✅ 1. Create CSR and Private Key

openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr

	•	openssl req: Starts the process of creating a Certificate Signing Request (CSR).
	•	-new: Generates a new CSR.
	•	-newkey rsa:2048: Creates a new 2048-bit RSA private key.
	•	-nodes: Prevents the private key from being encrypted with a passphrase (useful for servers).
	•	-keyout server.key: Saves the private key to server.key.
	•	-out server.csr: Saves the CSR to server.csr.

Purpose: You generate a private key and a CSR file. The CSR is what you send to the Certificate Authority (CA) to request an SSL certificate.

⸻

✅ 2. Send the CSR to the Certificate Authority (CA)

Submit server.csr to the SSL provider (e.g., GoDaddy, DigiCert, Let’s Encrypt) to get your SSL certificate issued.

⸻

✅ 3. Upload the Validation File

The CA usually requires you to verify domain ownership.

Instruction:
	•	They provide a validation file (e.g., ABC123.txt).
	•	Upload it to:
public_html/.well-known/pki-validation/ABC123.txt

The CA will check your domain to confirm that the validation file exists. If it does, they’ll proceed to issue the certificate.

⸻

✅ 4. Concatenate the Certificate Files into a Bundle

cat your_domain.crt your_ca_bundle.crt > bundle.crt

Or in your instruction:
Concatenate the .crt + .ca-bundle into bundle.crt

	•	.crt: Your primary SSL certificate.
	•	.ca-bundle: Intermediate and root certificates.
	•	bundle.crt: The combined certificate file used by the server.

⸻

✅ 5. Upload bundle.crt to the SSL Folder

Place the final certificate file (bundle.crt) in the path:

ssl/

This is where your NGINX or web server expects the SSL certificate to be.

⸻

✅ 6. Restart NGINX to Apply the SSL Certificate

nginx -t && service nginx restart

	•	nginx -t: Tests your NGINX configuration to ensure there are no errors.
	•	service nginx restart: Restarts NGINX to apply the new SSL certificate.

⚠️ If the config test fails, do not restart — fix the issue first.

⸻

✅ Summary Workflow
	1.	🔑 Create CSR and private key.
	2.	📩 Send CSR to CA.
	3.	✅ Upload validation file for domain verification.
	4.	📦 Concatenate certificate + CA bundle.
	5.	📁 Upload to ssl/ directory.
	6.	🔁 Restart NGINX.




create CSR file in ssl folder => openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr
send CSR key to validate
upload response file on path public_html/.well-known/pki-validation/
concatinate the two files into bundle.crt (.crt + .ca-bundle)
upload bundle.crt on path ssl/
restart nginx (nginx -t && service nginx restart)
