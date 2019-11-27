/**
Multiple ways of using worker:
1) Put in separate file and call with `new Worker('myScript.js')`

2) Put in same file, convert to Blob Url, and call with
   `new Worker(URL.createObjectURL(new Blob([stringOfWebworkerInstance])))`
    
  2.1) Separate script tag in same document:

        <script id="workerScript" type="javascript/worker">
            self.onmessage = e => {
                self.postMessage('Received: ' + e.data + 'Sent: message from worker');
            }
        </script>

        where:
        stringOfWebworkerInstance = document.getElementById('workerScript').textContent

  2.2) Same body as main JavaScript, where the worker is first instantiated and then
       stringified (shown below).
       Note that here we use the module pattern to call the function immediately
       in order to run the worker code
       i.e. (function MyWorker() {...})()
       but it's unnecessary in the <script/> from 2.1 since the worker code has
       already been parsed
*/
function MyWorker() {
    self.onmessage = e => {
        const data = e.data;
        self.postMessage('Received "' + data.message + '" from ' + data.name);
    }
}

const blob = new Blob(["(" + MyWorker.toString() + ")()"]);
const blobURL = window.URL.createObjectURL(blob);
const worker = new Worker(blobURL);

// same as worker.onmessage = e => {...}
worker.addEventListener('message', e => {
    document.write(e.data);
});
worker.addEventListener('error', e => {
    console.log("Error (" + e.message + ") thrown in file (" +
              e.filename + ") at line (" + e.lineno + ")");
});

worker.postMessage({ name: 'worker', message: 'message-from-window'});
