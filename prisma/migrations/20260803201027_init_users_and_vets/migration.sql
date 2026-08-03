-- CreateTable
CREATE TABLE `users` (
    `id` VARCHAR(36) NOT NULL,
    `username` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `hash_pass` VARCHAR(255) NOT NULL,
    `rol` ENUM('OWNER', 'VETERINARY', 'ADMIN') NOT NULL DEFAULT 'OWNER',
    `is_premium` BOOLEAN NOT NULL DEFAULT false,
    `id_card_url` VARCHAR(255) NULL,
    `photo_url` VARCHAR(255) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `users_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `veterinary_profiles` (
    `id` VARCHAR(36) NOT NULL,
    `user_id` VARCHAR(36) NOT NULL,
    `cv_url` VARCHAR(255) NULL,
    `recommendation_form_url` VARCHAR(255) NULL,
    `cabinet_name` VARCHAR(150) NULL,
    `is_checked` BOOLEAN NOT NULL DEFAULT false,
    `last_active_at` DATETIME(3) NULL,

    UNIQUE INDEX `veterinary_profiles_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `veterinary_profiles` ADD CONSTRAINT `veterinary_profiles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
