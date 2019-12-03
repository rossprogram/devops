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

## The gradebook

The Doenet gradebook is an SPA, written in Vue, providing a nice UI
for the RESTful API.

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

## The database server

The [database server](https://github.com/doenet/lrs) provides the LRS
itself and is deployed on vultr at `api.doenet.cloud`.  Deployment
happens via nixops.

Most users will access this API by using the aforementioned
[JavaScript library](https://github.com/doenet/api), so I suspect few
people will want to configure their own server.

I provisioned two machines on vultr; the machines are called
`database` and `webserver`.  I set them up using the NixOS image from
the ISO Library, and then used [vultr.sh](./vultr.sh) to install NixOS
onto the disk.

I created an A record pointing `api.doenet.cloud` to the IP address of
the `webserver` machine.

The two machines can then be configured via
```
nixops create -d doenet doenet.nix
nixops deploy
```

## The library

The [JavaScript library](https://github.com/doenet/api) is made
available on `npm`.

# Demo page

I'll put up a demo page soon, illustrating the JavaScript library.
