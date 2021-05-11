use strict; # Pay now or pay later
use warnings;

use File::Basename;
use Time::Local;
use File::Temp;

# To use local modules in current dir instead of configured lib modules
use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/./");
use my_lib; # local module


# our for global variables, my for local
our $scriptName = basename($0);


# Call main function in background
&main();


sub main {
    my $obj = funcReturningObj('a', 'b', 'c');
    my $objStatus = $obj->{status};

    # Connect to logical DB: ETS_AIPDB
    my $aipDbConnection = aip_db->new();
    my $aipDbReturnCode = $aipDbConnection->{retval};
    my $aipDbErrMsg = $aipDbConnection->{errmsg};
    my $aipDbHandle = $aipDbConnection->{aip_dbh};
    my $aipDbLoadHandle = $aipDbConnection->{aip_load_dbh};

    if ($aipDbReturnCode != SUCCESS) {
        sendErrorEmail("Get DB connections failed", $aipDbReturnCode, $aipDbErrMsg);
    } else {
        # my_lib->func(args) uses inheritance, e.g. my_lib->func(Foo, arg1) will pass Foo as the first arg
        # my_lib::func(args) doesn't use inheritance, so only the arguments passed will be parsed
        my ($getScheduledInvsRetCode, $getScheduledInvsErrMsg, $resultsMatrix, $columnNames) =
            my_lib::getAllScheduledInvestmentsForDate(
                $databaseHandle
                # Optional second arg to specify the date and/or time
                , DateTime->new(day=>10, month=>02, year=>2021, hour=>7, minute=>30)
            );

        if ($getScheduledInvsRetCode == SUCCESS) {
            my $emailSubject = "Today's Planned Orders run by " . $scriptName;
            my $columnDelimiter = " | ";
            # Note that since array pointers are returned, you must reference the array itself via `@{$arrayHandle}`
            # join('myDelimiter', array) outputs a string
            my $attachmentBody = join($columnDelimiter, @{$columnNames})."\n";

            # Iterating through matrix, again referencing the array via `@{$arrayHandle}`
            for my $row (@{$resultsMatrix}) {
                $attachmentBody .= join($columnDelimiter, @{$row})."\n";
            }

            SendEmail($emailSubject, "", $getScheduledInvsRetCode, $attachmentBody);
        } else {
            # handle error
            sendErrorEmail("SQL query handling failed", $getScheduledInvsRetCode, $getScheduledInvsErrMsg);
        }
    }

    $aipDbConnection->old(); # disconnect from DB
}

sub funcReturningObj {
    # Read arguments via array spreading
    my ($arg1, $arg2, $arg3) = @_;
    my $status = 'something';
    my $errMsg = 'something';

    return {
        'status' => $status,
        'errMsg' => $errMsg
    };
}

sub createTempFile {
    my ($fileName, $extension) = @_;

    my ($sec, $min, $hour, $day, $month, $year) = localtime(); # could also be `my @dateParts = localtime()` to get array
    $month++; # Months range from 0-11
    $year += 1900; # year == num years from 1900
    my $currentDate = sprintf("%02d-%02d-%04d", $month, $day, $year);

    # Temp files require at least four X's to append a hash to them. See [File::Temp Perl docs](https://perldoc.perl.org/File::Temp#tempfile)
    # sprintf("string", args) : numDigits-decimal/number
    my $tempFileTemplate = $fileName . "_" . sprintf("%02d-%02d-%04d", $month, $day, $year) . ".XXXX";

    # Could also be `File::Temp->new(...)` via inheritance
    return new File::Temp(TEMPLATE => $tempFileTemplate, UNLINK=>1, SUFFIX=>$extension);
}

sub sendErrorEmail {
    my ($subject, $returnCode, $errMsg) = @_;
    my $email_subject = ($subject." for ".$ScriptName);
    my $logmsg = ("------------------------------------------------\n" .
        $email_subject . "\n" . $errMsg . "\n" .
        "------------------------------------------------\n"
    );
    my $email_msg = $errMsg;

    output_to_log(ERROR, $logmsg);
    SendEmail($email_subject, $email_msg, $returnCode);
}

sub SendEmail {
    my ($emailSubject, $messageBody, $retCode, $attachmentBody) = @_;
    my $jobStatus = '';

    if ($retCode == SUCCESS) {
        $jobStatus = 'SUCCESS';
    } else {
        $jobStatus = 'FAILURE';
    }

    my $subject = "[$jobStatus] ($ET_ENV) AIP ETF Report - Scheduled Investments - ".$emailSubject;

    my $message .= "Started:  " . time2str("%C", $StartTime) . "\n";
    $message .= "Ended:    " . time2str("%C", time()) . "\n\n";
    $message .= "Response: \n $messageBody";

    if ((defined $messageBody) and ($messageBody ne "")) {
        $message .= "Response: \n $messageBody";
    }

    &Et_Run_Log("Sending Email\n") if ($Debug & 2);
    &Et_Run_Log("To: $EmailAddressList") if ($Debug & 2);
    &Et_Run_Log("Subject: $subject") if ($Debug & 2);
    &Et_Run_Log("Message: $message") if ($Debug & 2);
    &Et_Run_Log("SmtpServer: $smtpServer") if ($Debug & 2);

    if (defined $attachmentBody) {
        my $tempAttachmentFile = createTempFile('MyFileName', '.csv');

        # `print [output] [input]` will print to the console if no output provided, otherwise to the output
        # Here, we output to the temp file instead of the console
        print $tempAttachmentFile $attachmentBody;

        &et_email::Et_Mail("$EmailAddressList", "$subject", "$message", "$smtpServer", $tempAttachmentFile);
    } else {
        &et_email::Et_Mail("$EmailAddressList", "$subject", "$message", "$smtpServer");
    }
}

sub getAllScheduledInvestmentsForDate {
    my ($dbHandle, $date) = @_;
    my ($getScheduledInvsRetCode, $getScheduledInvsErrMsg) = (SUCCESS, ""); # SUCCESS was a const defined elsewhere

    my $currentDate = time();
    my $oneDayEpochTime = 60*60*24;
    my $selectedDate = $currentDate;

    if ((defined $date) and ($date->isa('DateTime'))) {
        # Time was an epoch number in seconds, not milliseconds
        $selectedDate = $date->epoch();
    }

    # Pad the scheduled investment date range from 1 day ago to 2 days in the future
    # (i.e. Monday - Wednesday) to account for days the market is closed, like holidays
    my $fromDate = $selectedDate - $oneDayEpochTime;
    my $toDate = $selectedDate + (2 * $oneDayEpochTime);

    my $getScheduledInvsSql = "
    WITH proj_invs_for_date AS (
        SELECT *
        FROM ETS_AIP.aip_projected_plan_investment
        WHERE
            investment_dt >= ?
            AND
            investment_dt <= ?
    )
    SELECT
        plan_id,
        account_id,
        symbol,
        proj_inv.investment_amount AS recurring_amount,
        NVL(inv.mf_initial_investment_amount, 0) AS initial_amount,
        REPLACE(proj_inv.security_type, 'EQ', 'ETF') AS security_type,
        TO_CHAR(TIMESTAMP '1970-01-01 00:00:00 UTC' + NUMTODSINTERVAL(investment_dt, 'SECOND'), 'mm-dd-yyyy') AS investment_date,
        user_id,
        plan.original_plan_id,
        inv.dividend_reinvest_cd,
        inv.commission
    FROM proj_invs_for_date proj_inv
    JOIN ETS_AIP.aip_plan_investment inv
        USING (plan_id, account_id, symbol)
    JOIN ETS_AIP.aip_plan plan
        USING (plan_id, account_id)
    WHERE
        plan.status_cd IN (1, 8)
        AND inv.status_cd = 1
        AND proj_inv.status_cd = 1
    ";

    # one-line if-else statement
    my $sqlQueryHandle = $dbHandle->prepare($getScheduledInvsSql)
        or $getScheduledInvsRetCode = DBA_PREPARE_ERROR;

    if ($getScheduledInvsRetCode != SUCCESS) {
        $getScheduledInvsErrMsg = aip_util::get_db_error_message($dbHandle);
        return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg);
    }

    # SQL prepared statements use index+1
    $sqlQueryHandle->bind_param(1, $fromDate);
    $sqlQueryHandle->bind_param(2, $toDate);

    $sqlQueryHandle->execute()
        or $getScheduledInvsRetCode = DBA_EXECUTE_ERROR;

    if ($getScheduledInvsRetCode != SUCCESS) {
        $getScheduledInvsErrMsg = aip_util::get_db_error_message($dbHandle);
        return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg);
    }

    my @resultsMatrix = (); # a list uses `@` and `()`

    # Note the weird way to append to an array
    # Like below, you pass the (dereferenced) array pointer to the call to `push(array, entry)`
    while (my @row = $sqlQueryHandle->fetchrow_array()) {
        push(@resultsMatrix, \@row);
    }

    # another list, this time with values in it
    my @columnNames = (
        "Plan ID",
        "Account ID",
        "Symbol",
        "Recurring Amount",
        "Initial Amount",
        "Security Type",
        "Investment Date",
        "User ID",
        "Original Plan ID",
        "Dividend Reinvestment Code",
        "Commission Code"
    );

    # Can only return array pointers, not the arrays themselves
    # Uses \@myArray syntax
    return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg, \@resultsMatrix, \@columnNames);
}

sub getAllScheduledInvestmentsForDate_oldVersion_onlyOnDate {
    my ($dbHandle, $date) = @_;
    my ($getScheduledInvsRetCode, $getScheduledInvsErrMsg) = (SUCCESS, "");

    my ($sec, $min, $hour, $day, $mon, $year) = localtime();
    $mon++; # Months range from 0-11
    $year += 1900; # year == num years from 1900
    my $currentDate = sprintf("%02d-%02d-%04d", $mon, $day, $year);
    my $selectedDate = $currentDate;

    if ((defined $date) and ($date->isa('DateTime'))) {
        $selectedDate = $date->mdy();
    }

    # Other ways of getting dates in Oracle DB
    # WITH today AS (
    #     --SELECT TO_CHAR(CURRENT_TIMESTAMP, 'mm-dd-yyyy') AS full_date FROM DUAL
    #     SELECT TO_CHAR(TIMESTAMP '2021-02-02 00:00:00 UTC', 'mm-dd-yyyy') AS full_date FROM DUAL
    # ),;
    # WITH proj_invs_with_date_ts AS (
    #     SELECT
    #         TO_CHAR(TIMESTAMP '1970-01-01 00:00:00 UTC' + NUMTODSINTERVAL(investment_dt, 'SECOND'), 'mm-dd-yyyy') AS investment_date_ts,
    #         appi.*
    #     FROM ETS_AIP.aip_projected_plan_investment appi
    # ),;

    my $getScheduledInvsSql = "
    WITH proj_invs_with_date_ts AS (
        SELECT
            TO_CHAR(TIMESTAMP '1970-01-01 00:00:00 UTC' + NUMTODSINTERVAL(investment_dt, 'SECOND'), 'mm-dd-yyyy') AS investment_date_ts,
            appi.*
        FROM ETS_AIP.aip_projected_plan_investment appi
    ),
    projected_investments_today AS (
        SELECT *
        FROM proj_invs_with_date_ts
        WHERE investment_date_ts = (
            ?
        )
    )
    SELECT
        plan_id,
        account_id,
        symbol,
        proj_inv.investment_amount AS recurring_amount,
        NVL(inv.mf_initial_investment_amount, 0) AS initial_amount,
        REPLACE(proj_inv.security_type, 'EQ', 'ETF') AS security_type,
        proj_inv.investment_date_ts,
        user_id,
        plan.original_plan_id,
        inv.dividend_reinvest_cd,
        inv.commission
    FROM projected_investments_today proj_inv
    JOIN ETS_AIP.aip_plan_investment inv
        USING (plan_id, account_id, symbol)
    JOIN ETS_AIP.aip_plan plan
        USING (plan_id, account_id)
    WHERE
        plan.status_cd IN (1, 8)
        AND inv.status_cd = 1
        AND proj_inv.status_cd = 1
    ";

    my $sqlQueryHandle = $dbHandle->prepare($getScheduledInvsSql)
        or $getScheduledInvsRetCode = DBA_PREPARE_ERROR;

    if ($getScheduledInvsRetCode != SUCCESS) {
        $getScheduledInvsErrMsg = aip_util::get_db_error_message($dbHandle);
        return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg);
    }

    $sqlQueryHandle->bind_param(1, $selectedDate);

    $sqlQueryHandle->execute()
        or $getScheduledInvsRetCode = DBA_EXECUTE_ERROR;

    if ($getScheduledInvsRetCode != SUCCESS) {
        $getScheduledInvsErrMsg = aip_util::get_db_error_message($dbHandle);
        return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg);
    }

    my @resultsMatrix = ();

    while (my @row = $sqlQueryHandle->fetchrow_array()) {
        push(@resultsMatrix, \@row);
    }

    my @columnNames = (
        "Plan ID",
        "Account ID",
        "Symbol",
        "Recurring Amount",
        "Initial Amount",
        "Security Type",
        "Investment Date",
        "User ID",
        "Original Plan ID",
        "Dividend Reinvestment Code",
        "Commission Code"
    );

    return ($getScheduledInvsRetCode, $getScheduledInvsErrMsg, \@resultsMatrix, \@columnNames);
}
