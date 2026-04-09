using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using System.Security.Cryptography;
using System.Text;
using InteriorDesignApp.Models;
using InteriorDesignApp.Data;

namespace InteriorDesignApp.Controllers
{
    public class AccountController : Controller
    {
        private readonly ApplicationDbContext _context;
        
        public AccountController(ApplicationDbContext context)
        {
            _context = context;
        }
        
        // GET: Index/Landing Page
        public IActionResult Index()
        {
            // Check if user is already logged in
            if (HttpContext.Session.GetString("UserId") != null)
            {
                return RedirectToAction("Home", "Design");
            }
            return View();
        }
        
        // GET: Sign In
        public IActionResult SignIn()
        {
            if (HttpContext.Session.GetString("UserId") != null)
            {
                return RedirectToAction("Home", "Design");
            }
            return View();
        }
        
        // POST: Sign In
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SignIn(string username, string password)
        {
            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                TempData["Error"] = "Please enter both username and password";
                return View();
            }
            
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
            
            if (user == null)
            {
                TempData["Error"] = "Invalid username or password";
                return View();
            }
            
            // Verify password
            if (!VerifyPassword(password, user.PasswordHash))
            {
                TempData["Error"] = "Invalid username or password";
                return View();
            }
            
            // Set session
            HttpContext.Session.SetString("UserId", user.Id.ToString());
            HttpContext.Session.SetString("Username", user.Username);
            
            return RedirectToAction("Home", "Design");
        }
        
        // GET: Sign Up
        public IActionResult SignUp()
        {
            return View();
        }
        
        // POST: Sign Up
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SignUp(string email, string username, string password, string confirmPassword)
        {
            // Validation
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                TempData["Error"] = "All fields are required";
                return View();
            }
            
            if (password != confirmPassword)
            {
                TempData["Error"] = "Passwords do not match";
                return View();
            }
            
            if (password.Length < 6)
            {
                TempData["Error"] = "Password must be at least 6 characters";
                return View();
            }
            
            // Check if username already exists
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
            if (existingUser != null)
            {
                TempData["Error"] = "Username already exists. Please choose another.";
                return View();
            }
            
            // Check if email already exists
            var existingEmail = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (existingEmail != null)
            {
                TempData["Error"] = "Email already registered. Please use another email or sign in.";
                return View();
            }
            
            // Create new user
            var user = new User
            {
                Email = email,
                Username = username,
                PasswordHash = HashPassword(password),
                CreatedAt = DateTime.Now
            };
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            TempData["Success"] = "Account created successfully! Please sign in.";
            return RedirectToAction("SignIn");
        }
        
        // GET: Forgot Password
        public IActionResult ForgotPassword()
        {
            return View();
        }
        
        // POST: Forgot Password
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(string email)
        {
            if (string.IsNullOrEmpty(email))
            {
                TempData["Error"] = "Please enter your email address";
                return View();
            }
            
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            
            if (user == null)
            {
                TempData["Error"] = "Email address not found in our records";
                return View();
            }
            
            // In a real app, send password reset email here
            // For demo, we'll just show a message
            TempData["Success"] = "Password reset link has been sent to your email address";
            return RedirectToAction("SignIn");
        }
        
        // GET: Logout
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Index");
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