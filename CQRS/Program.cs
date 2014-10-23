using Microsoft.Azure.WebJobs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Configuration;

using GalleryHelpers;
using System.Data.SqlClient;
using System.Linq.Expressions;

using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Queue;

namespace CQRS
{
    // To learn more about Microsoft Azure WebJobs, please see http://go.microsoft.com/fwlink/?LinkID=401557
    public class  Program
    {
        static string databaseWrite = "";
        static string databaseRead = "";
        static List<SiteLocation> locations = new List<SiteLocation>();
        public static JobHostConfiguration config;

        static public void Main()
        {
            var appSettings = System.Configuration.ConfigurationManager.AppSettings;
            
            var currentLocation = appSettings["siteName"];
            var blob = appSettings["blobContainer"];
            var dbRead = appSettings["dbRead"];
            var dbWrite = appSettings["dbWrite"];

            var queueName = appSettings["queueName"];

            var connectionStrings = System.Configuration.ConfigurationManager.ConnectionStrings;
            databaseRead = connectionStrings[dbRead].ConnectionString;
            databaseWrite = connectionStrings[dbWrite].ConnectionString;
            
            Console.WriteLine("currentLocation\t" + currentLocation);
            Console.WriteLine("blob\t" + blob);
            Console.WriteLine("queue name\t" + queueName);
            Console.WriteLine("dbRead\t" + dbRead);
            Console.WriteLine("dbWrite\t" + dbWrite);
            Console.WriteLine("databaseRead\t" + databaseRead);
            Console.WriteLine("databaseWrite\t" + databaseWrite);


            Console.WriteLine("Discovering Storage Locations...");

            for (int i = 0; i < connectionStrings.Count; i++)
            {
                Console.WriteLine("Connection String Name " + connectionStrings[i].Name);
                Console.WriteLine("Connection String String " + connectionStrings[i].ConnectionString);
                Console.WriteLine("Connection String Provider " + connectionStrings[i].ProviderName);

                if (connectionStrings[i].ProviderName == "" && !connectionStrings[i].Name.Contains("Local"))
                {
                    Console.WriteLine("Adding Storage Location:\t" + connectionStrings[i].Name);

                    if (currentLocation == connectionStrings[i].Name)
                    {
                        config = new JobHostConfiguration(connectionStrings[i].ConnectionString);
                        config.Queues.MaxPollingInterval = TimeSpan.FromMinutes(0.2);
                        config.Queues.MaxDequeueCount = 2;
                        config.Queues.BatchSize = 10;
                    }
                    locations.Add(new SiteLocation(connectionStrings[i].Name, connectionStrings[i].ConnectionString, blob, queueName));
                }
            }

            if (locations.Count > 0)
            {
                Console.WriteLine("Total Storage Locations: " + locations.Count);
                JobHost host = new JobHost(config);
                host.RunAndBlock();
            }
            else 
            {
                Console.WriteLine("ERROR: No storage locations found!");
            }
            


        }


        public static void processQueue([QueueTrigger("scaledemo")] Message m)
        {
            Console.WriteLine(m.operation + ": " + m.galleryObject);
            Console.WriteLine(m.serializedobject);

            if (m.galleryObject.ToString() == typeof(Photos).FullName)
            {
                var v = new Photos();
                v = (Photos)JsonConvert.DeserializeObject(m.serializedobject, typeof(Photos));
                v.connectionString = databaseWrite;

                if (m.operation == "delete")
                {
                    v.delete();

                }
                else if (m.operation == "insert")
                {
                    //Read the files form the _tmp storage in the stamp
                    var fullsize = v.read(v.tmpLocation + @"full\" + v.fileName);
                    var large = v.read(v.tmpLocation + @"large\" + v.fileName);
                    var medium = v.read(v.tmpLocation + @"medium\" + v.fileName);
                    var small = v.read(v.tmpLocation + @"small\" + v.fileName);
                    var thumb = v.read(v.tmpLocation + @"thumb\" + v.fileName);

                    //for each copy of the site
                    foreach (var l in locations)
                    {
                        //Upload the files to blob
                        var ash = new azureStorageHelper(l.storageAccount, l.storageAccountKey);
                        ash.blobUpload(fullsize, v.fileName, "full", l.blobContainer);
                        ash.blobUpload(large, v.fileName, "large", l.blobContainer);
                        ash.blobUpload(medium, v.fileName, "medium", l.blobContainer);
                        ash.blobUpload(small, v.fileName, "small", l.blobContainer);
                        ash.blobUpload(thumb, v.fileName, "thumb", l.blobContainer);
                    }
                    v.insert();         //Write the file to the db
                    v.cleanFile();      //Delete _tmp file
                }
                else if (m.operation == "update")
                {
                    v.update();
                }
            }
            else if (m.galleryObject.ToString() == typeof(Tags).FullName)
            {
                var v = new Tags();
                v = (Tags)JsonConvert.DeserializeObject(m.serializedobject, typeof(Tags));
                v.connectionString = databaseWrite;

                if (m.operation == "update")
                {
                    v.update();
                }
            }
            else if (m.galleryObject.ToString() == typeof(Galleries).FullName)
            {
                var v = new Galleries();
                v = (Galleries)JsonConvert.DeserializeObject(m.serializedobject, typeof(Galleries));
                v.connectionString = databaseWrite;

                if (m.operation == "insert")
                {
                    v.insert();
                }
            }
            else if (m.galleryObject.ToString() == typeof(GalleryHelpers.Users).FullName)
            {
                var v = new Users();
                v = (Users)JsonConvert.DeserializeObject(m.serializedobject, typeof(Users));
                v.connectionString = databaseWrite;

                if (m.operation == "insert")
                {
                    v.insert();
                }
                else if (m.operation == "update")
                {
                    v.update();
                }
            }
        }
    }
}
