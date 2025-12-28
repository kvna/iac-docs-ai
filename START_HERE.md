# 🚀 START HERE - Quick Guide

**You asked "what do I do now?" - Here's your answer!**

---

## ⚡ **Fastest Way to Get Started** (Recommended)

Just run this **one command**:

```powershell
pwsh ./Quick-Start.ps1
```

That's it! The script will:
1. ✅ Check if you have all required tools installed
2. ✅ Verify you're logged into Azure
3. ✅ Check if you have Azure OpenAI access
4. ✅ Deploy everything to Azure (with your confirmation)
5. ✅ Show you what was created

**Time: ~15 minutes** | **Cost: ~$12/month** | **Can destroy anytime**

---

## 🔍 **Want to Check Prerequisites First?**

If you want to see what's needed before deploying:

```powershell
pwsh ./scripts/deployment/Test-Prerequisites.ps1
```

This shows you:
- ✓ What you have installed
- ✗ What's missing
- 💡 How to fix any issues

**No deployment happens** - just checking!

---

## 📖 **Just Want to Read First?**

If you prefer to understand before doing anything:

1. **Read the Proposal** (15 min):
   ```bash
   cat IaC_Documentation_Modernization_Proposal.md
   ```
   This explains what this project does and why it's valuable.

2. **Look at Sample Documentation** (10 min):
   ```bash
   cat docs/day1/concept-iac-overview.md
   cat docs/day1/howto-environment-setup.md
   ```
   See what the documentation looks like.

3. **Decide**: Deploy later or not at all - your choice!

---

## 🎯 **What Each Option Does**

| Option | What Happens | Time | Cost |
|--------|--------------|------|------|
| **Quick-Start.ps1** | Auto-checks + deploys to Azure | 15 min | ~$12/month* |
| **Test-Prerequisites.ps1** | Just checks, no deployment | 2 min | $0 |
| **Read proposal first** | Just reading, no actions | 15 min | $0 |

*Can be destroyed anytime to stop costs

---

## ❓ **Common Questions**

**Q: Will this cost me money?**
A: Only if you deploy (~$12/month). You can destroy everything anytime to stop costs.

**Q: What if I don't have Azure OpenAI access?**
A: The script will detect this and tell you how to request it. Takes 1-2 business days.

**Q: Can I test without deploying to Azure?**
A: Yes! You can use the documentation templates and validation scripts locally.

**Q: What if something breaks?**
A: Run `pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1` to clean everything up.

**Q: Do I need to know Terraform?**
A: No! The scripts handle everything. But you can learn by looking at the code.

---

## 🆘 **Need Help?**

1. **Prerequisites failing?** → Run `pwsh ./scripts/deployment/Test-Prerequisites.ps1` to see what's wrong
2. **Deployment failing?** → Check the error message, might be OpenAI access
3. **Still stuck?** → Open an issue or ask for help

---

## 🎉 **My Recommendation for You**

Based on you wanting to see it work:

```powershell
# Option 1: Just run this and follow the prompts
pwsh ./Quick-Start.ps1

# Option 2: Or check first, then decide
pwsh ./scripts/deployment/Test-Prerequisites.ps1
```

**Pick whichever makes you comfortable!**

---

## 📝 **What Happens After Deployment**

After successful deployment, you can:

1. ✅ Test document quality validation
2. ✅ Explore the documentation samples
3. ✅ Check Azure Portal to see resources
4. ✅ Review the system architecture
5. ⚠️ **REMEMBER**: Destroy when done to stop costs!

---

**Ready? Pick an option above and let's go! 🚀**
