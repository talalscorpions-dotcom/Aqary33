// S3 client and pre-signed URL helpers.
// Full Architecture Plan, Section 8.1 — two buckets: public-read media,
// private verification documents accessed only via short-lived signed URLs.
require("dotenv").config();
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({ region: process.env.AWS_REGION });

const BUCKETS = {
  media: process.env.S3_BUCKET_MEDIA,       // public-read: property photos/video
  documents: process.env.S3_BUCKET_DOCUMENTS, // private: title deeds, licences, IDs
};

/**
 * Issue a pre-signed PUT URL so the client uploads directly to S3 —
 * the file never passes through the API server itself.
 */
async function getUploadUrl(bucketKey, objectKey, contentType, expiresInSeconds = 300) {
  const bucket = BUCKETS[bucketKey];
  if (!bucket) throw new Error(`Unknown bucket key: ${bucketKey}`);
  const command = new PutObjectCommand({ Bucket: bucket, Key: objectKey, ContentType: contentType });
  const url = await getSignedUrl(s3, command, { expiresIn: expiresInSeconds });
  return { uploadUrl: url, publicUrl: `https://${bucket}.s3.${process.env.AWS_REGION}.amazonaws.com/${objectKey}` };
}

/**
 * Issue a short-lived signed GET URL for a private verification document,
 * generated on demand for an authorized reviewer only.
 */
async function getDocumentReadUrl(objectKey, expiresInSeconds = 300) {
  const command = new GetObjectCommand({ Bucket: BUCKETS.documents, Key: objectKey });
  return getSignedUrl(s3, command, { expiresIn: expiresInSeconds });
}

module.exports = { s3, BUCKETS, getUploadUrl, getDocumentReadUrl };
