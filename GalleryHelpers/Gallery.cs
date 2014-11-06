using System;
using System.Data.SqlClient;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GalleryHelpers
{
    public class GalleryObject
    {
        SqlCommand command;
        public string connectionString { get; set; }
        public bool nonquery(string query)
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    command = new SqlCommand(query, connection);
                    command.Connection.Open();

                    return command.ExecuteNonQuery() > 0 ? true : false;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("ERROR: " + e.Message);
                Console.WriteLine("ERROR: " + query);
                return false;
            }
        }
        public bool exist(string query)
        {
            int count = 0;
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    command = new SqlCommand(query, connection);
                    command.Connection.Open();
                    int.TryParse("" + command.ExecuteScalar(), out count);
                    return count > 0 ? true : false;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.InnerException);
                return false;
            }
        }
    }
    public class SiteLocation
    {
        public string name { get; set; }
        public string storageAccount { get; set; }
        public string storageAccountKey { get; set; }
        public string storageRoot { get; set; }
        public string blobContainer { get; set; }
        public string queue { get; set; }

        public SiteLocation(string LocationName, string connection, string containerName, string queueName)
        {
            name = LocationName;

            if (connection.Split(';').Count<string>() != 3)
            {
                throw new Exception("Invalid Storage connection string: " + connection);
            }
            else
            {
                storageAccount = connection.Split(';')[1].Replace("AccountName=", "");
                storageAccountKey = connection.Split(';')[2].Replace("AccountKey=", "");
                storageRoot = connection.Split(';')[0].Replace("DefaultEndpointsProtocol=", "");
                storageRoot += @"://" + storageAccount + ".blob.core.windows.net";
            }

            blobContainer = containerName;
            queue = queueName;
        }
    }
    public class Photos : GalleryObject
    {
        public int id { get; set; }
        public int galleryId { get; set; }
        public int userId { get; set; }
        public string fileTitle { get; set; }
        public string description { get; set; }
        public string fileType { get; set; }
        public string fileExtension { get; set; }
        public int fileSize { get; set; }
        public string uploadDate { get; set; }
        public string fileName { get; set; }
        public string tmpLocation { get; set; }

        public void insert()
        {
            var query = @"INSERT INTO Photos (GalleryId, UserId, Description, FileTitle, FileExtension, ContentType, FileSize, UploadDate, primaryURI) VALUES ";
            query += @" ('" + galleryId + "', '" + userId + "', '" + description + "', '" +
                fileTitle + "', '" + fileExtension + "', '" + fileType + "', '" +
                fileSize + "', '" + uploadDate + "', '" + fileName.Trim() + "')";

            nonquery(query);
        }

        public void delete()
        {
            //Delete Tags
            nonquery("DELETE FROM Photos_Tags WHERE Photos_Id = " + id);

            //Delete Comments
            nonquery("DELETE FROM Comments WHERE PhotoId = " + id);

            //Delete Picture
            nonquery("DELETE FROM Photos WHERE Id = " + id);
        }
        public void write(string path, byte[] payload)
        {
            var f = new FileStream(path, FileMode.CreateNew);

            foreach (var b in payload)
            {
                f.WriteByte(b);
            }
            f.Flush();
            f.Close();
        }

        public byte[] read(string file)
        {
            var f = new FileStream(file, FileMode.Open);

            var payload = new byte[f.Length];
            payload.Initialize();

            for (int i = 0; i < f.Length; i++)
            {
                payload[f.Position] = (byte)f.ReadByte();
            }
            f.Close();
            f.Dispose();
            return payload;
        }

        public void cleanFile()
        {
            try
            {
                File.Delete(tmpLocation + @"full\" + fileName);
                File.Delete(tmpLocation + @"large\" + fileName);
                File.Delete(tmpLocation + @"medium\" + fileName);
                File.Delete(tmpLocation + @"small\" + fileName);
                File.Delete(tmpLocation + @"thumb\" + fileName);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.InnerException);
            }
        }

        public void update()
        {
            nonquery(@"UPDATE Photos SET FileTitle = '" + this.fileTitle + "', Description = '" + this.description + "' WHERE Id = " + this.id);
        }
    }
    public class Galleries : GalleryObject
    {
        public string id { get; set; }
        public string name { get; set; }

        public void insert()
        {
            if (!exist(@"SELECT COUNT(*) FROM Galleries WHERE LOWER(Name) = '" + name.Trim() + "'"))
            {
                nonquery(@"INSERT INTO Galleries (Name) VALUES ('" + name.Trim() + "')");
            }
        }
    }
    public class Tags : GalleryObject
    {
        public int photoId;

        List<string> tagCollection { get; set; }

        private string tags;
        public string rawTags
        {
            get { return tags; }
            set
            {
                tags = value;
                tagCollection = new List<string>();
                var t = value.Split(';');
                foreach (var item in t)
                {
                    if (item.Trim().Length > 0)
                    {
                        tagCollection.Add(item.Trim().ToLowerInvariant());
                    }
                }
            }
        }

        public void update()
        {
            //Clear All Tags for this picture
            nonquery(@"DELETE FROM Photos_Tags WHERE Photos_Id = " + photoId);
            foreach (var tag in tagCollection)
            {
                if (!exist(@"SELECT COUNT(*) FROM Tags WHERE TagName = '" + tag + "'"))
                {
                    //If tag doesn't exist, create it
                    nonquery(@"INSERT INTO Tags (TagName) VALUES ('" + tag + "')");
                }
                //Associate image and tag
                nonquery(@"INSERT INTO Photos_Tags (Photos_Id, Tags_TagName) VALUES ('" + photoId + "', '" + tag + "')");
            }
        }
    }
    public class Users : GalleryObject
    {
        public int id { get; set; }
        public string bio { get; set; }
        public string displayName { get; set; }
        public string email { get; set; }

        public bool insert()
        {
            if (!exist("SELECT Email FROM UserProfiles WHERE LOWER(Email) = LOWER(" + email + ")"))
            {
                try
                {
                    nonquery(@"INSERT INTO UserProfiles (Email, DisplayName, Bio) VALUES ('" + email + "', '" + email + "', '')");
                    return true;
                }
                catch (Exception e)
                {
                    Console.WriteLine("Failed to Insert User" + e.Message);
                    return false;
                }
                
            }
            return false;
        }

        public void update()
        {
            nonquery(@"UPDATE UserProfiles SET DisplayName = '" + displayName + "', Bio = '" + bio + "' WHERE UserId = '" + id + "'");
        }
    }
    public class Message
    {
        public string operation { get; set; }
        public object galleryObject { get; set; }
        public string serializedobject { get; set; }
    }
}
