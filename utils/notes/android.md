Access internet on emulated device

1. Settings->Mobile network->Access Point Names
2. Create new APN with the following credentials:
    ```
    Name:   <arbitrary>
    APN:    www
    Proxy:  10.0.2.2     (this is a special port which means “use the computer”)
    Port:   ____     (use a port if needed by company proxy)
    ```
