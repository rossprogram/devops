# Setting up the domain and DNS

I registered `rossprogram.org` with [namecheap](https://namecheap.com/).

DNS is still managed with namecheap.

# Static content on rossprogram.org

We are hosting our static content from [a GitHub repository with GitHub pages](https://github.com/rossprogram/rossprogram.github.io).

# Email

We use [migadu](https://migadu.com) for email, and [Amazon
SES](https://aws.amazon.com/ses/) for automated email (e.g., handling
password requests during the application season).

# recommend.rossprogram.org

Teachers submit recommendations via a [recommendation
portal](https://recommend.rossprogram.org).  This is hosted on S3.  The source is available at https://github.com/rossprogram/recommend

# apply.rossprogram.org

Applicants submit their application materials via an [application
portal](https://apply.rossprogram.org).  This is hosted on S3.  The
source is available at https://github.com/rossprogram/apply

# The API server

The [API backend](https://github.com/rossprogram/api) provides 

To deploy, the key material must first be unlocked via
```
git-crypt unlock
```
This will decrypt the `.key` files which hold passwords and shared secrets.

Then the machines can then be deployed via
```
nixops create -d ross ross.nix
nixops deploy
```
Note that this also builds the API backend via [a nix expression](https://github.com/rossprogram/api/blob/master/default.nix).

It does not create the databases.  For this,
```
mongo
use ross
```

# The IPFS server

/dnsaddr/ipfs.rossprogram.org/tcp/4001/QmNjT28jp3MiaiMV9LTYPMwk1cSwDC5FNJURJTN23bxr4B

/ip4/18.191.230.175/tcp/4001/ipfs/QmNjT28jp3MiaiMV9LTYPMwk1cSwDC5FNJURJTN23bxr4B
