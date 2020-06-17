const AWS = require('aws-sdk')
const { hostname } = require('os')
const http = require('http');
const fetch = require('node-fetch');
const textract = new AWS.Textract({
    apiVersion: '2018-06-27',
    region: 'ap-southeast-2'
});

const port = 8080;

const server = http.createServer((req, res) => {
    const handleError = (err) => {
        res.statusCode = 500;
        res.setHeader('Content-Type', 'text/plain');
        return res.end(`Internal Server Error: 
        ${err}`);
    }

    fetch('http://www.moha.gov.my/images/maklumat_bahagian/KK/kdndomestic.pdf')
        .then(response => {
            return response.buffer()
        })
        .then(pdfBuffer => {
            textract.analyzeDocument({
                Document: {
                    Bytes: pdfBuffer
                },
                FeatureTypes: ["TABLES"]
            }, (err, data) => {
                if (err) {
                    return handleError(err)
                }
                res.statusCode = 200;
                res.setHeader('Content-Type', 'text/plain');
                return res.end(`Hello Textract: 
            ${JSON.stringify(data.Blocks, null, 2)}`)
            })
        })
        .catch(handleError);
})

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname()}:${port}/`)
})