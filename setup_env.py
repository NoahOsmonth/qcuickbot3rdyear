#!/usr/bin/env python3
"""
Environment Setup Script for QCUICKBOT
This script helps you set up your environment variables securely.
"""

import os
import sys

def main():
    print("🔐 QCUICKBOT Environment Setup")
    print("=" * 40)
    print()
    
    # Check if .env already exists
    if os.path.exists('.env'):
        print("⚠️  .env file already exists!")
        response = input("Do you want to overwrite it? (y/N): ").lower()
        if response != 'y':
            print("Setup cancelled.")
            return
    
    print("Please provide your API keys and configuration values.")
    print("Press Enter to skip any optional values.")
    print()
    
    env_vars = {}
    
    # Firebase Configuration
    print("🔥 Firebase Configuration:")
    env_vars['FIREBASE_WEB_API_KEY'] = input("Web API Key: ").strip()
    env_vars['FIREBASE_WEB_APP_ID'] = input("Web App ID: ").strip()
    env_vars['FIREBASE_AUTH_DOMAIN'] = input("Auth Domain: ").strip()
    env_vars['FIREBASE_MEASUREMENT_ID'] = input("Measurement ID: ").strip()
    
    env_vars['FIREBASE_ANDROID_API_KEY'] = input("Android API Key: ").strip()
    env_vars['FIREBASE_ANDROID_APP_ID'] = input("Android App ID: ").strip()
    
    env_vars['FIREBASE_IOS_API_KEY'] = input("iOS API Key: ").strip()
    env_vars['FIREBASE_IOS_APP_ID'] = input("iOS App ID: ").strip()
    env_vars['FIREBASE_IOS_BUNDLE_ID'] = input("iOS Bundle ID (default: com.example.qcuickbot): ").strip() or "com.example.qcuickbot"
    
    env_vars['FIREBASE_MACOS_API_KEY'] = input("macOS API Key: ").strip()
    env_vars['FIREBASE_MACOS_APP_ID'] = input("macOS App ID: ").strip()
    env_vars['FIREBASE_MACOS_BUNDLE_ID'] = input("macOS Bundle ID (default: com.example.qcuickbot): ").strip() or "com.example.qcuickbot"
    
    env_vars['FIREBASE_WINDOWS_API_KEY'] = input("Windows API Key: ").strip()
    env_vars['FIREBASE_WINDOWS_APP_ID'] = input("Windows App ID: ").strip()
    env_vars['FIREBASE_WINDOWS_MEASUREMENT_ID'] = input("Windows Measurement ID: ").strip()
    
    env_vars['FIREBASE_MESSAGING_SENDER_ID'] = input("Messaging Sender ID: ").strip()
    env_vars['FIREBASE_PROJECT_ID'] = input("Project ID: ").strip()
    env_vars['FIREBASE_STORAGE_BUCKET'] = input("Storage Bucket: ").strip()
    
    print()
    print("🤖 Gemini AI Configuration:")
    env_vars['GEMINI_API_KEY'] = input("Gemini API Key: ").strip()
    
    print()
    print("🗄️  Supabase Configuration (optional):")
    env_vars['SUPABASE_URL'] = input("Supabase URL: ").strip()
    env_vars['SUPABASE_ANON_KEY'] = input("Supabase Anon Key: ").strip()
    env_vars['SUPABASE_SERVICE_ROLE_KEY'] = input("Supabase Service Role Key: ").strip()
    
    # Write .env file
    print()
    print("📝 Writing .env file...")
    
    with open('.env', 'w') as f:
        f.write("# QCUICKBOT Environment Configuration\n")
        f.write("# Generated automatically - DO NOT commit to version control!\n\n")
        
        f.write("# Firebase Configuration\n")
        f.write("# Web Platform\n")
        f.write(f"FIREBASE_WEB_API_KEY={env_vars['FIREBASE_WEB_API_KEY']}\n")
        f.write(f"FIREBASE_WEB_APP_ID={env_vars['FIREBASE_WEB_APP_ID']}\n")
        f.write(f"FIREBASE_AUTH_DOMAIN={env_vars['FIREBASE_AUTH_DOMAIN']}\n")
        f.write(f"FIREBASE_MEASUREMENT_ID={env_vars['FIREBASE_MEASUREMENT_ID']}\n\n")
        
        f.write("# Android Platform\n")
        f.write(f"FIREBASE_ANDROID_API_KEY={env_vars['FIREBASE_ANDROID_API_KEY']}\n")
        f.write(f"FIREBASE_ANDROID_APP_ID={env_vars['FIREBASE_ANDROID_APP_ID']}\n\n")
        
        f.write("# iOS Platform\n")
        f.write(f"FIREBASE_IOS_API_KEY={env_vars['FIREBASE_IOS_API_KEY']}\n")
        f.write(f"FIREBASE_IOS_APP_ID={env_vars['FIREBASE_IOS_APP_ID']}\n")
        f.write(f"FIREBASE_IOS_BUNDLE_ID={env_vars['FIREBASE_IOS_BUNDLE_ID']}\n\n")
        
        f.write("# macOS Platform\n")
        f.write(f"FIREBASE_MACOS_API_KEY={env_vars['FIREBASE_MACOS_API_KEY']}\n")
        f.write(f"FIREBASE_MACOS_APP_ID={env_vars['FIREBASE_MACOS_APP_ID']}\n")
        f.write(f"FIREBASE_MACOS_BUNDLE_ID={env_vars['FIREBASE_MACOS_BUNDLE_ID']}\n\n")
        
        f.write("# Windows Platform\n")
        f.write(f"FIREBASE_WINDOWS_API_KEY={env_vars['FIREBASE_WINDOWS_API_KEY']}\n")
        f.write(f"FIREBASE_WINDOWS_APP_ID={env_vars['FIREBASE_WINDOWS_APP_ID']}\n")
        f.write(f"FIREBASE_WINDOWS_MEASUREMENT_ID={env_vars['FIREBASE_WINDOWS_MEASUREMENT_ID']}\n\n")
        
        f.write("# Common Firebase Settings\n")
        f.write(f"FIREBASE_MESSAGING_SENDER_ID={env_vars['FIREBASE_MESSAGING_SENDER_ID']}\n")
        f.write(f"FIREBASE_PROJECT_ID={env_vars['FIREBASE_PROJECT_ID']}\n")
        f.write(f"FIREBASE_STORAGE_BUCKET={env_vars['FIREBASE_STORAGE_BUCKET']}\n\n")
        
        f.write("# Gemini AI Configuration\n")
        f.write(f"GEMINI_API_KEY={env_vars['GEMINI_API_KEY']}\n\n")
        
        if env_vars['SUPABASE_URL']:
            f.write("# Supabase Configuration\n")
            f.write(f"SUPABASE_URL={env_vars['SUPABASE_URL']}\n")
            f.write(f"SUPABASE_ANON_KEY={env_vars['SUPABASE_ANON_KEY']}\n")
            f.write(f"SUPABASE_SERVICE_ROLE_KEY={env_vars['SUPABASE_SERVICE_ROLE_KEY']}\n\n")
        
        f.write("# IMPORTANT: Never commit this file to version control!\n")
    
    print("✅ .env file created successfully!")
    print()
    print("🔒 Security Reminders:")
    print("1. Your .env file is now in .gitignore")
    print("2. Never commit .env to version control")
    print("3. Keep your API keys secure and private")
    print("4. Consider using a secrets management service for production")
    print()
    print("🚀 You can now run your Flutter app!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nSetup cancelled.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
