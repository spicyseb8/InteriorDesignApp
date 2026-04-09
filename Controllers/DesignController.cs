using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using InteriorDesignApp.Data;
using InteriorDesignApp.Models;
using System.Security.Cryptography;
using System.Text;

namespace InteriorDesignApp.Controllers
{
    public class DesignController : Controller
    {
        private readonly ApplicationDbContext _context;
        
        public DesignController(ApplicationDbContext context)
        {
            _context = context;
        }
        
        // GET: Home Page
        public IActionResult Home()
        {
            // Check if user is logged in
            var userId = HttpContext.Session.GetString("UserId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Account");
            }
            
            ViewBag.Username = HttpContext.Session.GetString("Username");
            return View();
        }
        
        // GET: Settings
        public IActionResult Settings()
        {
            var userId = HttpContext.Session.GetString("UserId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Account");
            }
            
            return View();
        }
        
        // GET: Profile
        public IActionResult Profile()
        {
            var userId = HttpContext.Session.GetString("UserId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Account");
            }
            
            var user = _context.Users.Find(int.Parse(userId));
            if (user == null)
            {
                return RedirectToAction("SignIn", "Account");
            }
            
            return View(user);
        }
        
        // POST: Update Profile
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateProfile(int id, string username, string currentPassword, string newPassword, string confirmNewPassword)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }
            
            // Update username if changed
            if (!string.IsNullOrEmpty(username) && username != user.Username)
            {
                // Check if username is taken
                var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == username && u.Id != id);
                if (existingUser != null)
                {
                    TempData["Error"] = "Username already taken";
                    return RedirectToAction("Profile");
                }
                user.Username = username;
                HttpContext.Session.SetString("Username", username);
            }
            
            // Update password if provided
            if (!string.IsNullOrEmpty(newPassword))
            {
                if (string.IsNullOrEmpty(currentPassword))
                {
                    TempData["Error"] = "Current password is required to change password";
                    return RedirectToAction("Profile");
                }
                
                // Verify current password
                if (!VerifyPassword(currentPassword, user.PasswordHash))
                {
                    TempData["Error"] = "Current password is incorrect";
                    return RedirectToAction("Profile");
                }
                
                if (newPassword != confirmNewPassword)
                {
                    TempData["Error"] = "New passwords do not match";
                    return RedirectToAction("Profile");
                }
                
                if (newPassword.Length < 6)
                {
                    TempData["Error"] = "Password must be at least 6 characters";
                    return RedirectToAction("Profile");
                }
                
                user.PasswordHash = HashPassword(newPassword);
            }
            
            await _context.SaveChangesAsync();
            TempData["Success"] = "Profile updated successfully!";
            return RedirectToAction("Profile");
        }
        
        // GET: MyProjects
        public IActionResult MyProjects()
        {
            var userId = HttpContext.Session.GetString("UserId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Account");
            }
            
            var projects = _context.Projects
                .Where(p => p.UserId == int.Parse(userId))
                .OrderByDescending(p => p.CreatedAt)
                .ToList();
            
            return View(projects);
        }
        
        // GET: Privacy
        public IActionResult Privacy()
        {
            return View();
        }
        
        // GET: Terms
        public IActionResult Terms()
        {
            return View();
        }
        
        // Helper methods for password hashing
        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }
        
        private bool VerifyPassword(string password, string hash)
        {
            var hashOfInput = HashPassword(password);
            return hashOfInput == hash;
        }
    }
}