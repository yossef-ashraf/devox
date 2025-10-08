It looks like GitHub is rejecting your release because of an issue with the **tag name**. Here are a few things to check:  

### 1. **Ensure You Have a Tag**  
When creating a release, GitHub requires a tag. If you haven't created one, you need to do it manually using:  

```sh
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```
Replace `v1.0.0` with your desired version number.

### 2. **Verify the Tag Format**  
Your tag name must follow a valid semantic versioning format, such as:  
✅ `v1.0.0`  
✅ `1.0.0`  
🚫 `version 1` (spaces are not allowed)  
🚫 `v1..0` (double dots are invalid)  

### 3. **Ensure the Tag Exists on GitHub**  
Run the following to check if the tag is correctly pushed:  

```sh
git tag
git ls-remote --tags origin
```
If the tag isn’t listed in `ls-remote`, push it:  

```sh
git push --tags
```

### 4. **Delete and Recreate the Tag (If Needed)**  
If you suspect the tag is corrupted, delete and recreate it:  

```sh
git tag -d v1.0.0
git push origin --delete v1.0.0
git tag -a v1.0.0 -m "Fixing release tag"
git push origin v1.0.0
```

### 5. **Try Creating the Release Again**  
Now go back to GitHub and create the release again. If you’re using the API, ensure you pass the correct tag in the request.

Let me know if you still face issues! 🚀