var AWS = require('aws-sdk');

// Set the region
AWS.config.update({region: 'us-west-2'});

// Create EC2 service object
var ec2 = new AWS.EC2({apiVersion: '2016-11-15'});

// EC2 instance parameters
var instanceParams = {
   ImageId: 'ami-0c55b159cbfafe1f0', 
   InstanceType: 't2.micro',
   KeyName: 'your-key-pair-name',
   MinCount: 1,
   MaxCount: 1
};

// Create a new EC2 instance
ec2.runInstances(instanceParams, function(err, data) {
  if (err) {
    console.log("Could not create instance", err);
    return;
  }
  var instanceId = data.Instances[0].InstanceId;
  console.log("Created instance", instanceId);
});

// Create S3 service object
var s3 = new AWS.S3({apiVersion: '2006-03-01'});

// S3 bucket parameters
var bucketParams = {
  Bucket : 'your-bucket-name'
};

// Create a new S3 bucket
s3.createBucket(bucketParams, function(err, data) {
  if (err) {
    console.log("Error", err);
  } else {
    console.log("Success", data.Location);
  }
});// Create a new S3 bucket
s3.createBucket(bucketParams, function(err, data) {
  if (err) {
    console.log("Error", err);
  } else {
    console.log("Success", data.Location);
  }
});

// Create a new S3 bucket
s3.deleteBucket(bucketParams, function(err, data) {
  if (err) {
    console.log("Error", err);
  } else {
    console.log("Success", data.Location);
  }
});
