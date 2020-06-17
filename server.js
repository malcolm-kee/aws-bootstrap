const { S3 } = require('aws-sdk')
const { hostname } = require('os')
const http = require('http');

const s3 = new S3({
    apiVersion: '2006-03-01'
});

const port = 8080;

const server = http.createServer((req, res) => {
    s3.listBuckets((err, data) => {
        if (err) {
            res.statusCode = 500;
            res.setHeader('Content-Type', 'text/plain');
            return res.end(`Error: ${err}`)
        }
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.end(`Hello Cloud ${req.headers["user-agent"]}
        from ${hostname()}
        Bucket name ${process.env.TEXTRACT_S3_BUCKET}
        Bucket data: ${JSON.stringify(data.Buckets, null, 2)}
        `);
    })
})

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname()}:${port}/`)
})