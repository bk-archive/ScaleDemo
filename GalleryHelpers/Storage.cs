using System;
using System.Collections.Generic;
using System.Linq;
using System.Drawing;
using System.Drawing.Imaging;

using Newtonsoft.Json;

using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Queue;
using Microsoft.WindowsAzure.Storage.Blob;

namespace GalleryHelpers
{
    public class azureStorageHelper
    {
        StorageCredentials sCredentials;
        CloudStorageAccount storageAccount;
        CloudQueueClient queueClient;
        CloudQueue queue;
        CloudBlobClient blobClient;
        CloudBlobContainer blob;
        CloudBlockBlob blockBlob;
        BlobContainerPermissions permisions;
        public azureStorageHelper(string acountName, string accountKey)
        {
            sCredentials = new StorageCredentials(acountName, accountKey);
            storageAccount = new CloudStorageAccount(sCredentials, true);

            queueClient = storageAccount.CreateCloudQueueClient();
            blobClient = storageAccount.CreateCloudBlobClient();
            permisions = new BlobContainerPermissions();
            permisions.PublicAccess = BlobContainerPublicAccessType.Container;
        }

        public bool enqueue(string queueName, Message operationMessage)
        {
            var message = JsonConvert.SerializeObject(operationMessage);

            try
            {
                queue = queueClient.GetQueueReference(queueName);
                queue.CreateIfNotExists();


                queue.AddMessage(new CloudQueueMessage(message));
                return true;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.InnerException);
                return false;
            }
        }


        public bool blobUpload(byte[] content, string filename, string folder, string container)
        {
            try
            {
                blob = blobClient.GetContainerReference(container);
                blob.CreateIfNotExists();

                blockBlob = blob.GetBlockBlobReference(folder + @"/" + filename);

                //upload to tmp container
                blockBlob.UploadFromByteArray(content, 0, content.Count<byte>(), null, null, null);

                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public Image blobThumbnail(string filename, string container)
        {

            try
            {
                blob = blobClient.GetContainerReference(container);
                blob.CreateIfNotExists();

                blockBlob = blob.GetBlockBlobReference(@"thumb/" + filename);
                using (var outStream = new System.IO.MemoryStream())
                {
                    blockBlob.DownloadToStream(outStream);

                    return Image.FromStream(outStream);
                }

            }
            catch (Exception e)
            {
                Console.WriteLine(e.InnerException);
                return null;
            }
        }
    }
}
