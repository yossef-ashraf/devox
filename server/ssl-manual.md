### 1. **Create the CSR (Certificate Signing Request) File**:
   **Goal**: Create a Certificate Signing Request (CSR) with the private key, which will be sent to the certificate provider (like PR in this case) to obtain a new SSL certificate.

   **Steps**:
   - Open the command line (Terminal).
   - Navigate to the folder where your SSL certificates are stored (e.g., `ssl`).
   - Run the following command to generate the CSR file (with the private key):

     ```bash
     openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr
     ```

     - **-new**: Creates a new request.
     - **-newkey rsa:2048**: Creates a new key using RSA algorithm with 2048-bit length.
     - **-nodes**: Means "no DES" (i.e., do not encrypt the private key with a passphrase).
     - **-keyout server.key**: Specifies the output file for the private key (`server.key`).
     - **-out server.csr**: Specifies the output file for the CSR (`server.csr`).

   **Result of this step**:
   - The `server.key` file contains the private key.
   - The `server.csr` file contains the certificate signing request.

### 2. **Send the CSR File to PR**:
   - After generating the `server.csr` file, send it to PR so he can provide the necessary SSL certificate for you.
   - Once PR receives the request, he will send you the SSL certificate along with the CA (Certificate Authority) file, if required.

### 3. **Upload the Validation File to the Server**:
   **Goal**: To verify that you own the domain for which you're installing the certificate. Certificate providers use a method of verification via uploading a file to the specified path on the server.

   - Receive the files sent by PR, which will usually include a file like `validation.txt` or similar.
   - Upload these files to the following path on your server:
     ```
     /path/to/your/project/public_html/.well-known/pki-validation/
     ```

   - **Note**: Ensure that the path `public_html/.well-known/pki-validation/` exists on your server. If it does not exist, create it.

### 4. **Concatenate the Certificates into a `bundle.crt` File**:
   **Goal**: Combine the main SSL certificate with the CA Bundle file, which contains all the intermediate certificates that may be needed to ensure your SSL certificate is trusted by all browsers.

   - After receiving the certificate from PR, you will typically receive two files:
     - **The certificate (`.crt`)**: The main SSL certificate.
     - **The CA bundle (`.ca-bundle`)**: The intermediate certificates that help complete the chain of trust.

   - Combine the certificates into one file using the `cat` command:
     ```bash
     cat server.crt intermediate.crt > bundle.crt
     ```

     - `server.crt`: The file containing your main SSL certificate.
     - `intermediate.crt`: The file containing the intermediate certificates.
     - `bundle.crt`: The resulting file containing the concatenated certificates.

   **Result**: You now have the `bundle.crt` file, which contains both the main certificate and the intermediate certificates.

### 5. **Upload the `bundle.crt` File to the SSL Directory**:
   **Goal**: Install the certificate on the server.

   - Upload the `bundle.crt` file to the directory where the SSL certificates are stored on your server. Typically, this directory is located at:
     ```
     /path/to/ssl/
     ```

### 6. **Restart the Nginx Service**:
   **Goal**: Apply the new certificate by restarting the Nginx service.

   - First, verify that the Nginx configuration files do not contain any errors:
     ```bash
     nginx -t
     ```

   - If there are no errors, restart Nginx to apply the changes:
     ```bash
     service nginx restart
     ```

   - **Note**: If you're using a system with `systemd`, use the following command instead:
     ```bash
     systemctl restart nginx
     ```

### 7. **Verify the Certificate**:
   - After restarting Nginx, you can verify that the certificate has been installed correctly by using a web browser or tools like [SSL Labs](https://www.ssllabs.com/ssltest/) to check the SSL certificate's validity.

---

### Additional Notes:
- Ensure that your server is properly configured to use HTTPS in the Nginx configuration files.
- You may need to modify your Nginx server block settings to point to the correct SSL certificate files:
  ```nginx
  ssl_certificate /path/to/ssl/bundle.crt;
  ssl_certificate_key /path/to/ssl/server.key;
  ```