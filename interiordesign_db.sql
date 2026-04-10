-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 10, 2026 at 01:57 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `interiordesign_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalculateProjectCost` (IN `p_ProjectId` INT, OUT `p_TotalCost` DECIMAL(12,2))   BEGIN
    DECLARE v_furnitureCost DECIMAL(12,2);
    DECLARE v_materialCost DECIMAL(12,2);
    DECLARE v_laborCost DECIMAL(12,2);
    
    -- Calculate furniture cost
    SELECT COALESCE(SUM(CASE 
        WHEN pf.CustomPrice IS NOT NULL THEN pf.CustomPrice * pf.Quantity
        ELSE fl.BasePrice * pf.Quantity 
    END), 0)
    INTO v_furnitureCost
    FROM ProjectFurniture pf
    JOIN FurnitureLibrary fl ON pf.FurnitureId = fl.Id
    WHERE pf.ProjectId = p_ProjectId;
    
    -- Calculate material cost
    SELECT COALESCE(SUM(CASE 
        WHEN pm.CustomPrice IS NOT NULL THEN pm.CustomPrice * pm.Quantity
        ELSE ml.BasePrice * pm.Quantity 
    END), 0)
    INTO v_materialCost
    FROM ProjectMaterials pm
    JOIN MaterialLibrary ml ON pm.MaterialId = ml.Id
    WHERE pm.ProjectId = p_ProjectId;
    
    -- Calculate labor cost (30% of materials + furniture)
    SET v_laborCost = (v_furnitureCost + v_materialCost) * 0.30;
    
    -- Total cost
    SET p_TotalCost = v_furnitureCost + v_materialCost + v_laborCost;
    
    -- Update project total
    UPDATE Projects 
    SET TotalEstimatedCost = p_TotalCost
    WHERE Id = p_ProjectId;
    
    -- Save to cost estimates history
    INSERT INTO CostEstimates (ProjectId, EstimatedCost, FurnitureCost, MaterialCost, LaborCost)
    VALUES (p_ProjectId, p_TotalCost, v_furnitureCost, v_materialCost, v_laborCost);
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `costestimates`
--

CREATE TABLE `costestimates` (
  `Id` int(11) NOT NULL,
  `ProjectId` int(11) NOT NULL,
  `EstimatedCost` decimal(12,2) NOT NULL,
  `FurnitureCost` decimal(12,2) DEFAULT NULL,
  `MaterialCost` decimal(12,2) DEFAULT NULL,
  `LaborCost` decimal(12,2) DEFAULT NULL,
  `Breakdown` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`Breakdown`)),
  `GeneratedAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `furniturelibrary`
--

CREATE TABLE `furniturelibrary` (
  `Id` int(11) NOT NULL,
  `FurnitureName` varchar(200) NOT NULL,
  `Category` varchar(50) NOT NULL,
  `SubCategory` varchar(50) DEFAULT NULL,
  `Description` text DEFAULT NULL,
  `BasePrice` decimal(10,2) NOT NULL,
  `PricePerUnit` varchar(20) DEFAULT 'piece',
  `Dimensions` varchar(100) DEFAULT NULL,
  `Model3DURL` varchar(500) DEFAULT NULL,
  `ThumbnailURL` varchar(500) DEFAULT NULL,
  `IsActive` tinyint(1) DEFAULT 1,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `furniturelibrary`
--

INSERT INTO `furniturelibrary` (`Id`, `FurnitureName`, `Category`, `SubCategory`, `Description`, `BasePrice`, `PricePerUnit`, `Dimensions`, `Model3DURL`, `ThumbnailURL`, `IsActive`, `CreatedAt`) VALUES
(1, 'Modern Sofa', 'Living Room', 'Seating', 'Contemporary L-shaped sofa with premium fabric', 25000.00, 'piece', '200x80x70 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(2, 'Dining Table', 'Dining Room', 'Tables', '6-seater wooden dining table', 18000.00, 'piece', '150x90x75 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(3, 'Queen Bed', 'Bedroom', 'Beds', 'Upholstered queen size bed frame', 22000.00, 'piece', '160x200x100 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(4, 'Office Desk', 'Home Office', 'Desks', 'Ergonomic computer desk with storage', 8500.00, 'piece', '120x60x74 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(5, 'Bookshelf', 'Living Room', 'Storage', '5-tier wooden bookshelf', 7500.00, 'piece', '80x30x180 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(6, 'Nightstand', 'Bedroom', 'Storage', 'Modern bedside table with drawer', 3500.00, 'piece', '50x40x50 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(7, 'Coffee Table', 'Living Room', 'Tables', 'Minimalist round coffee table', 5500.00, 'piece', '80x80x45 cm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(8, 'Wardrobe', 'Bedroom', 'Storage', '3-door sliding wardrobe', 32000.00, 'piece', '180x60x210 cm', NULL, NULL, 1, '2026-04-09 22:24:58');

-- --------------------------------------------------------

--
-- Table structure for table `materiallibrary`
--

CREATE TABLE `materiallibrary` (
  `Id` int(11) NOT NULL,
  `MaterialName` varchar(200) NOT NULL,
  `Category` varchar(50) NOT NULL,
  `MaterialType` varchar(50) DEFAULT NULL,
  `Description` text DEFAULT NULL,
  `BasePrice` decimal(10,2) NOT NULL,
  `PriceUnit` varchar(20) DEFAULT 'sqm',
  `Color` varchar(50) DEFAULT NULL,
  `Texture` varchar(50) DEFAULT NULL,
  `IsActive` tinyint(1) DEFAULT 1,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `materiallibrary`
--

INSERT INTO `materiallibrary` (`Id`, `MaterialName`, `Category`, `MaterialType`, `Description`, `BasePrice`, `PriceUnit`, `Color`, `Texture`, `IsActive`, `CreatedAt`) VALUES
(1, 'Ceramic Floor Tiles', 'Flooring', 'Tile', 'Premium glazed ceramic tiles', 850.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(2, 'Hardwood Flooring', 'Flooring', 'Wood', 'Solid oak wood flooring', 2500.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(3, 'Vinyl Planks', 'Flooring', 'Vinyl', 'Waterproof luxury vinyl planks', 1200.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(4, 'Wall Paint - Premium', 'Wall Finish', 'Paint', 'Low VOC premium wall paint', 450.00, 'gallon', NULL, NULL, 1, '2026-04-09 22:24:58'),
(5, 'Wallpaper', 'Wall Finish', 'Wallpaper', 'Textured vinyl wallpaper', 650.00, 'roll', NULL, NULL, 1, '2026-04-09 22:24:58'),
(6, 'Granite Countertop', 'Kitchen', 'Stone', 'Premium granite slab', 3800.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(7, 'Quartz Countertop', 'Kitchen', 'Stone', 'Engineered quartz surface', 4200.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58'),
(8, 'Glass Partition', 'Division', 'Glass', 'Tempered glass partition', 2800.00, 'sqm', NULL, NULL, 1, '2026-04-09 22:24:58');

-- --------------------------------------------------------

--
-- Table structure for table `projectfurniture`
--

CREATE TABLE `projectfurniture` (
  `Id` int(11) NOT NULL,
  `ProjectId` int(11) NOT NULL,
  `FurnitureId` int(11) NOT NULL,
  `Quantity` int(11) DEFAULT 1,
  `CustomPrice` decimal(10,2) DEFAULT NULL,
  `PositionX` decimal(10,2) DEFAULT 0.00,
  `PositionY` decimal(10,2) DEFAULT 0.00,
  `PositionZ` decimal(10,2) DEFAULT 0.00,
  `Rotation` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `projectmaterials`
--

CREATE TABLE `projectmaterials` (
  `Id` int(11) NOT NULL,
  `ProjectId` int(11) NOT NULL,
  `MaterialId` int(11) NOT NULL,
  `Quantity` decimal(10,2) DEFAULT 1.00,
  `CustomPrice` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `projects`
--

CREATE TABLE `projects` (
  `Id` int(11) NOT NULL,
  `UserId` int(11) NOT NULL,
  `ProjectName` varchar(200) NOT NULL,
  `RoomDimensions` varchar(100) DEFAULT NULL,
  `RoomType` varchar(50) DEFAULT NULL,
  `DesignData` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`DesignData`)),
  `TotalEstimatedCost` decimal(12,2) DEFAULT NULL,
  `Status` enum('draft','completed','shared') DEFAULT 'draft',
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `projects`
--

INSERT INTO `projects` (`Id`, `UserId`, `ProjectName`, `RoomDimensions`, `RoomType`, `DesignData`, `TotalEstimatedCost`, `Status`, `CreatedAt`, `UpdatedAt`) VALUES
(1, 1, 'Modern Living Room', '5x4 meters', 'Living Room', NULL, NULL, 'draft', '2026-04-09 22:24:59', '2026-04-09 22:24:59');

--
-- Triggers `projects`
--
DELIMITER $$
CREATE TRIGGER `update_projects_timestamp` BEFORE UPDATE ON `projects` FOR EACH ROW BEGIN
    SET NEW.UpdatedAt = CURRENT_TIMESTAMP;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `Id` varchar(255) NOT NULL,
  `UserId` int(11) DEFAULT NULL,
  `Data` text DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `LastAccessed` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ExpiresAt` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `Id` int(11) NOT NULL,
  `Email` varchar(255) NOT NULL,
  `Username` varchar(100) NOT NULL,
  `PasswordHash` varchar(255) NOT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `LastLogin` timestamp NULL DEFAULT NULL,
  `IsActive` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`Id`, `Email`, `Username`, `PasswordHash`, `CreatedAt`, `UpdatedAt`, `LastLogin`, `IsActive`) VALUES
(1, 'test@example.com', 'testuser', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', '2026-04-09 22:24:59', '2026-04-09 22:24:59', NULL, 1),
(2, 'seb@example.com', 'Seb', 'jZae727K08KaOmKSgOaGzww/XVqGr/PKEgIMkjrcbJI=', '2026-04-09 22:37:56', '2026-04-09 22:37:56', NULL, 1);

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `update_users_timestamp` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN
    SET NEW.UpdatedAt = CURRENT_TIMESTAMP;
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `costestimates`
--
ALTER TABLE `costestimates`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_project_estimates` (`ProjectId`),
  ADD KEY `idx_generated` (`GeneratedAt`);

--
-- Indexes for table `furniturelibrary`
--
ALTER TABLE `furniturelibrary`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_category` (`Category`),
  ADD KEY `idx_price` (`BasePrice`),
  ADD KEY `idx_active` (`IsActive`);
ALTER TABLE `furniturelibrary` ADD FULLTEXT KEY `ft_search` (`FurnitureName`,`Description`);

--
-- Indexes for table `materiallibrary`
--
ALTER TABLE `materiallibrary`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_category` (`Category`),
  ADD KEY `idx_material_type` (`MaterialType`),
  ADD KEY `idx_active` (`IsActive`);
ALTER TABLE `materiallibrary` ADD FULLTEXT KEY `ft_search` (`MaterialName`,`Description`);

--
-- Indexes for table `projectfurniture`
--
ALTER TABLE `projectfurniture`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_project` (`ProjectId`),
  ADD KEY `idx_furniture` (`FurnitureId`);

--
-- Indexes for table `projectmaterials`
--
ALTER TABLE `projectmaterials`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_project` (`ProjectId`),
  ADD KEY `idx_material` (`MaterialId`);

--
-- Indexes for table `projects`
--
ALTER TABLE `projects`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_user_projects` (`UserId`),
  ADD KEY `idx_status` (`Status`),
  ADD KEY `idx_created` (`CreatedAt`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `idx_user_session` (`UserId`),
  ADD KEY `idx_expires` (`ExpiresAt`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`Id`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `Username` (`Username`),
  ADD KEY `idx_username` (`Username`),
  ADD KEY `idx_email` (`Email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `costestimates`
--
ALTER TABLE `costestimates`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `furniturelibrary`
--
ALTER TABLE `furniturelibrary`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `materiallibrary`
--
ALTER TABLE `materiallibrary`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `projectfurniture`
--
ALTER TABLE `projectfurniture`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `projectmaterials`
--
ALTER TABLE `projectmaterials`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `projects`
--
ALTER TABLE `projects`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `costestimates`
--
ALTER TABLE `costestimates`
  ADD CONSTRAINT `costestimates_ibfk_1` FOREIGN KEY (`ProjectId`) REFERENCES `projects` (`Id`) ON DELETE CASCADE;

--
-- Constraints for table `projectfurniture`
--
ALTER TABLE `projectfurniture`
  ADD CONSTRAINT `projectfurniture_ibfk_1` FOREIGN KEY (`ProjectId`) REFERENCES `projects` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `projectfurniture_ibfk_2` FOREIGN KEY (`FurnitureId`) REFERENCES `furniturelibrary` (`Id`);

--
-- Constraints for table `projectmaterials`
--
ALTER TABLE `projectmaterials`
  ADD CONSTRAINT `projectmaterials_ibfk_1` FOREIGN KEY (`ProjectId`) REFERENCES `projects` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `projectmaterials_ibfk_2` FOREIGN KEY (`MaterialId`) REFERENCES `materiallibrary` (`Id`);

--
-- Constraints for table `projects`
--
ALTER TABLE `projects`
  ADD CONSTRAINT `projects_ibfk_1` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE;

--
-- Constraints for table `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
