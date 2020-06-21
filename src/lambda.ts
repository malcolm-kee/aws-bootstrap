import type { SNSHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';

const dbClient = new DynamoDB.DocumentClient();

export const handleSns: SNSHandler = async function myHandler(event) {
  await dbClient
    .put({
      TableName: '',
      Item: {},
    })
    .promise();

  event.Records.forEach((record) => {
    console.log(record);
  });
};
