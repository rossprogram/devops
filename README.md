# Deploying the Doenet cloud services

The Doenet cloud services are available at [doenet.cloud](https://doenet.cloud/).

Most users can simply rely on that public server, but some
institutions may want to set up their own instance of the Doenet cloud
services.  These brief instructions explain how
[doenet.cloud](https://doenet.cloud/) is configured.

## Setting up the domain and DNS

I registered `doenet.cloud` with [namecheap](https://namecheap.com/), where
I chose Custom DNS and pointed to the AWS Route 53 nameservers.

On AWS, I created a Hosted Zone on Amazon Route 53 for `doenet.cloud`,
and created MX records pointing to [migadu](https://migadu.com/).

## The library

The [JavaScript library](https://github.com/doenet/api) is made
available on `npm`.

## The database server

The [database server](https://github.com/doenet/lrs) provides the LRS
itself.  Most users will access this API by using the aforementioned
[JavaScript library](https://github.com/doenet/api).

The [database server](https://github.com/doenet/lrs) is deployed on
Amazon EC2 at `api.doenet.cloud`.

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
