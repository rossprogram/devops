# Deploying the Doenet cloud services

The Doenet cloud services are available at [doenet.cloud](https://doenet.cloud/).

Most users can simply rely on that public server, but some
institutions may want to set up their own instance of the Doenet cloud
services.  These brief instructions explain how
[doenet.cloud](https://doenet.cloud/) was configured.

## Setting up the domain and DNS

I registered `doenet.cloud` with [namecheap](https://namecheap.com/), where
I chose Custom DNS and pointed to the AWS Route 53 nameservers.

On AWS, I created a Hosted Zone on Amazon Route 53 for `doenet.cloud`,
and created MX records pointing to [migadu](https://migadu.com/).

## The LRS frontend (or "gradebook")

The Doenet gradebook is an SPA, written in
[Vue.js](https://vuejs.org), providing a nice UI for the [RESTful API](https://en.wikipedia.org/wiki/Representational_state_transfer).

To build and deploy, from the [gradebook repository](http://github.com/doenet/gradebook), run
```
npm run-script build
npm run-script deploy
```
This is configured to deploy to an S3 bucket, which is served from
CloudFront in order to get everything behind SSL.

There is some additional configuration for an SPA on the CloudFront
side, specifically

- routing 404s to index.html,
- setting the "Default Root Object" to `/index.html` so that
  https://doenet.cloud/ resolves to the index page.

One could also configure the S3 bucket to /not/ be world-readable but
it doesn't much matter.

## The LRS backend

The [LRS backend](https://github.com/doenet/lrs) provides the LRS
itself and is deployed on [vultr](vultr.com) at `api.doenet.cloud`.
Deployment happens via [NixOps](https://nixos.org/nixops/).

Most users will access this API by using the [JavaScript
library](https://github.com/doenet/api), so I suspect few people will
want to configure their own server.  Once we have federation set up,
this will be a more common desire.

I provisioned two machines on [vultr](vultr.com); the machines are
called `database` and `webserver`.  I set them up using the NixOS
image from the ISO Library, and then used [vultr.sh](./vultr.sh) to
install a clean copy of NixOS onto the disk.

With Route 53, I created an A record pointing `api.doenet.cloud` to
the IP address of the `webserver` machine.  (This could also have been
done via nixops.)

To deploy, the key material must first be unlocked via
```
git-crypt unlock
```
This will decrypt the `.key` files which hold passwords and shared secrets.

Then the machines can then be deployed via
```
nixops create -d doenet doenet.nix
nixops deploy
```
Note that this also builds the LRS backend via [a nix expression](https://github.com/Doenet/lrs/blob/master/default.nix).

It does not create the appropriate databases though.  For this,
```
mongo 10.1.96.3/admin -u root -p PASSWORD
use lrs
db.createUser( {user:"lrs", pwd: "...", roles: [ { role: "readWrite", db:"lrs" } ] } )
```


## The library

The [JavaScript library](https://github.com/doenet/api) is made
available on `npm`.

# Demo page

I'll put up a demo page soon, illustrating the JavaScript library.
