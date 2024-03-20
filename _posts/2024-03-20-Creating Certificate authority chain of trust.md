---
layout: post
title: "Creating Certificate authority chain of trust with OpenSSL"
date: "2024-03-20 14:15"
---

# Problem

The Certificate signing request flow is a complicated process that involves an end-entity certificate, intermediate certificate, and certificate authority.

The following describes how they all work together in order to create a chain of trust.

# Solution

1. Create a self-signed root certificate authority directory tree.

        mkdir root-ca && cd root-ca
        mkdir certs crl csr newcerts private
        cp /etc/pki/tls/openssl.cnf .
        touch serial index.txt
        echo "1000" >> serial

2. Modify the openssl.cnf configuration file.

        vim openssl.cnf
        # openssl.cnf
        ....
        [ CA_default ]
        dir             = /my/path/to/root-ca           # Where everything is kept
        certificate     = $dir/certs/root-ca.cert.pem  # The CA certificate
        private_key     = $dir/private/root-ca.key.pem # The private key
        ....
        [ usr_cert ]
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign
        ....
        [ v3_inter_ca ]
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true, pathlen:0
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign

        [ end_entity_cert ]
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer:always
        basicConstraints = CA:FALSE
        nsCertType = server
        keyUsage = critical, digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth
        nsComment = "OpenSSL Generated Server Certificate"

3. Generate a root certificate private key with a pass phrase.

        openssl genrsa -out private/root-ca.key.pem -aes256 4096
        chmod 0400 private/root-ca.key.pem

        # [NOTE] Certificate authorities it is best practice to specify a higher value key size.

4. Verify that the root CA private key can be used with the provided passphrase.

        openssl rsa -check -noout -in private/root-ca.key.pem

5. Generate a root certificate certificate signing request (CSR).

        openssl req -config openssl.cnf -new -sha256 -key private/root-ca.key.pem -out csr/root-ca.csr.pem

        You are about to be asked to enter information that will be incorporated
        into your certificate request.
        What you are about to enter is what is called a Distinguished Name or a DN.
        There are quite a few fields but you can leave some blank
        For some fields there will be a default value,
        If you enter '.', the field will be left blank.
        -----
        Country Name (2 letter code) [XX]:US
        State or Province Name (full name) []:North Carolina
        Locality Name (eg, city) [Default City]:Raleigh
        Organization Name (eg, company) [Default Company Ltd]:Red Hat
        Organizational Unit Name (eg, section) []:Central IT
        Common Name (eg, your name or your server's hostname) []:Root CA 
        Email Address []:

        Please enter the following 'extra' attributes
        to be sent with your certificate request
        A challenge password []:
        An optional company name []:

6. Verify the root certificate CSR and change permissions of the CSR.

        chmod 0444 csr/root-ca.csr.pem
        openssl req -in csr/root-ca.csr.pem -noout -text

7. Create a self-signed root CA certificate.

        openssl req -config openssl.cnf -key private/root-ca.key.pem -in csr/root-ca.csr.pem -x509 -days 7305 -sha256 -extensions v3_ca -out certs/root-ca.cert.pem
        chmod 0444 certs/root-ca.cert.pem

8. Verify the root certificate.

        openssl x509 -in certs/root-ca.cert.pem -text -noout

9.  Create a intermediate certificate directory tree.

        cd .. && mkdir inter-ca && cd inter-ca
        mkdir certs crl csr newcerts private
        cp ../root-ca/openssl.cnf .
        touch serial index.txt
        echo "1000" >> serial

10. Modify the openssl.cnf configuration file.

        vim openssl.cnf
        # openssl.cnf
        ....
        [ CA_default ]
        dir             = /my/path/to/inter-ca           # Where everything is kept
        certificate     = $dir/certs/inter-ca.cert.pem  # The CA certificate
        private_key     = $dir/private/inter-ca.key.pem # The private key
        ....
        policy		= policy_anything

11. Generate a intermediate certificate private key with a pass phrase.

        openssl genrsa -out private/inter-ca.key.pem -aes256 4096
        chmod 0400 private/inter-ca.key.pem

12. Verify that the intermediate certificate private key can be used with the provided passphrase.

        openssl rsa -check -noout -in private/inter-ca.key.pem

13. Generate a intermediate certificate certificate signing request (CSR).

        openssl req -config openssl.cnf -new -sha256 -key private/inter-ca.key.pem -out csr/inter-ca.csr.pem
        Enter pass phrase for private/inter-ca.key.pem:                                                                       
        You are about to be asked to enter information that will be incorporated                                              
        into your certificate request.                                                                                        
        What you are about to enter is what is called a Distinguished Name or a DN.                                           
        There are quite a few fields but you can leave some blank                                                             
        For some fields there will be a default value,                                                                        
        If you enter '.', the field will be left blank.                                                                       
        -----                                                                                                                 
        Country Name (2 letter code) [XX]:US                                                                                  
        State or Province Name (full name) []:North Carolina
        Locality Name (eg, city) [Default City]:Raleigh                                                                       
        Organization Name (eg, company) [Default Company Ltd]:Red Hat                                                         
        Organizational Unit Name (eg, section) []:Central IT                                                                  
        Common Name (eg, your name or your server's hostname) []:Inter CA                                                     
        Email Address []:                                                                                                     
                                                                                                                        
        Please enter the following 'extra' attributes                                                                         
        to be sent with your certificate request                                                                              
        A challenge password []:                                                                                              
        An optional company name []:

14. Verify the intermediate certificate CSR and change permissions of the CSR.

        chmod 0444 csr/inter-ca.csr.pem
        openssl req -in csr/inter-ca.csr.pem -noout -text

15. Create intermediate certificate that is signed by the root CA.

        cd ../root-ca
        openssl ca -config openssl.cnf -md sha256 -extensions v3_inter_ca -days 1825 -notext -in ../inter-ca/csr/inter-ca.csr.pem  -out ../inter-ca/certs/inter-ca.cert.pem

16. Update the permissions on the certificate and validate the certificate against the root CA.

         cd ../inter-ca/
         chmod 0444 certs/inter-ca.cert.pem
         openssl verify -CAfile ../root-ca/certs/root-ca.cert.pem certs/inter-ca.cert.pem

17. Create the chained certificate.

        cat certs/inter-ca.cert.pem ../root-ca/certs/root-ca.cert.pem > certs/ca-chain.cert.pem
        chmod 0444 certs/ca-chain.cert.pem

18. Issue a new certificate for the end-entity by first creating a private key.

        openssl genrsa -out private/example.com.key.pem 2048
        chmod 0400 private/example.com.key.pem

19. Generate a certificate certificate signing request (CSR) for your end-entity.

        openssl req -config openssl.cnf -new -sha256 -key private/example.com.key.pem -out csr/example.com.csr.pem
        You are about to be asked to enter information that will be incorporated
        into your certificate request.
        What you are about to enter is what is called a Distinguished Name or a DN.
        There are quite a few fields but you can leave some blank
        For some fields there will be a default value,
        If you enter '.', the field will be left blank.
        -----
        Country Name (2 letter code) [XX]:US
        State or Province Name (full name) []:North Carolina
        Locality Name (eg, city) [Default City]:Raleigh
        Organization Name (eg, company) [Default Company Ltd]:Red Hat 
        Organizational Unit Name (eg, section) []:Web Admin 
        Common Name (eg, your name or your server's hostname) []:example.com
        Email Address []:

        Please enter the following 'extra' attributes
        to be sent with your certificate request
        A challenge password []:
        An optional company name []:

20. Verify the end-entity certificate CSR and change permissions of the CSR.

        chmod 0444 csr/example.com.csr.pem
        openssl req -in csr/example.com.csr.pem -noout -text

21. Issue the end-entity certificate.

        openssl ca -config openssl.cnf -notext -md sha256 -extensions end_entity_cert -days 365 -in csr/example.com.csr.pem -out certs/example.com.cert.pem
        chmod 0444 certs/example.com.cert.pem

22. Verify the certificate against the chained certificate.

        openssl verify -CAfile certs/ca-chain.cert.pem certs/example.com.cert.pem


# Summary

This exercise was an example of how to build a certificate authority hierarchy.