using System.ComponentModel.DataAnnotations;

namespace InteriorDesignApp.Models
{
    public class Project
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string ProjectName { get; set; } = string.Empty;
        
        public string? RoomDimensions { get; set; }
        
        public string? DesignData { get; set; } // JSON string for 3D design data
        
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        
        public int UserId { get; set; }
        public User? User { get; set; }
    }
}