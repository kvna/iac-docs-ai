# Test Questions for AI Documentation Assistant

## Single-Source Questions
*These should pull from one primary document*

### From: concept-iac-overview.md
1. "What is Infrastructure as Code?"
2. "Why should I use IaC instead of manual deployment?"
3. "What are the benefits of Infrastructure as Code?"
4. "When should I use IaC vs manual processes?"
5. "Is IaC declarative or imperative?"
6. "What does version control mean for infrastructure?"

### From: howto-environment-setup.md
7. "How do I install Terraform?"
8. "What version of Azure CLI do I need?"
9. "How do I configure Git for the first time?"
10. "What are the prerequisites for setting up my development environment?"
11. "How do I verify my Terraform installation?"
12. "What PowerShell version is required?"

### From: reference-naming-conventions.md
13. "What naming convention should I use for storage accounts?"
14. "How should I name a resource group in Azure?"
15. "What are the environment codes I should use in resource names?"
16. "What separator should I use in Azure resource names?"
17. "How do I name shared resources?"
18. "What is the format for naming Azure resources?"

## Multi-Source Questions (2 sources)
*These should combine information from two documents*

### Concept + How-To
19. "Why is IaC important and how do I get started?"
20. "What is Infrastructure as Code and what tools do I need to use it?"
21. "Explain IaC benefits and tell me what I need to install"
22. "I'm new to IaC, what is it and how do I set up my computer?"

### Concept + Naming
23. "What is IaC and are there naming standards I should follow?"
24. "How does version control relate to resource naming?"
25. "What's the philosophy behind IaC and how should I name my infrastructure?"

### How-To + Naming
26. "What tools do I need and what naming conventions should I use?"
27. "How do I set up Terraform and what should I name my Azure resources?"
28. "What environment should I configure and what environment codes exist for naming?"

## Multi-Source Questions (3 sources)
*These should require all three documents to answer comprehensively*

### Comprehensive Questions
29. "I'm completely new to infrastructure as code. What is it, what do I need to install, and what naming standards should I follow?"

30. "Walk me through getting started with Infrastructure as Code from concept to practice"

31. "What are the fundamentals I need to know about IaC, what tools are required, and what standards should I follow?"

32. "How do I go from zero to deploying infrastructure with proper naming conventions?"

33. "What is the complete setup process for Infrastructure as Code development?"

34. "Explain IaC philosophy, required tooling, and Azure naming best practices"

35. "I need to onboard a new team member - what concepts, tools, and standards should they know?"

## Cross-Cutting Questions
*These test ability to synthesize information across topics*

36. "How does the environment I set up relate to environment naming codes?"

37. "Why is version control important for IaC and what tool do I use for it?"

38. "What's the relationship between declarative infrastructure and naming conventions?"

39. "How do the tools I install help me follow naming conventions?"

40. "What does a complete IaC workflow look like from setup to deployment?"

## Specificity Test Questions
*Testing precision vs. generalization*

### Very Specific
41. "What exact command do I run to install Terraform on Windows?"
42. "What is the three-letter code for a resource group?"
43. "Is Terraform version 1.5+ required?"

### Somewhat Vague (should still work)
44. "How do I get my computer ready?"
45. "What should I call my Azure stuff?"
46. "Why is code better than clicking?"

### Conceptual
47. "What's the difference between manual infrastructure and IaC?"
48. "How does IaC improve team collaboration?"
49. "What makes infrastructure repeatable?"

## Edge Cases
*Testing what happens with unclear or out-of-scope questions*

50. "How do I deploy a Kubernetes cluster?" *(Not in docs - should say so)*

51. "What is Docker?" *(Not in docs - should say so)*

52. "How much does Azure cost?" *(Not in docs - should say so)*

53. "What programming language is Terraform written in?" *(Not in docs - should say so)*

## Recommended Testing Sequence

### Phase 1: Verify Single-Source (Pick 2 from each)
- Question 1 (IaC concept)
- Question 7 (Tool installation)
- Question 13 (Naming convention)

### Phase 2: Test Multi-Source Combination
- Question 19 (Concept + How-To)
- Question 26 (How-To + Naming)
- Question 29 (All 3 sources)

### Phase 3: Test Synthesis
- Question 35 (Onboarding - requires comprehensive answer)
- Question 40 (Complete workflow)

### Phase 4: Test Edge Cases
- Question 50 (Out of scope - should admit lack of info)
- Question 45 (Vague but answerable)

## Expected Behaviors

**Good Responses Should:**
- ✅ Cite relevant sources at the bottom
- ✅ Provide specific examples from docs
- ✅ Use bullet points/numbered lists for clarity
- ✅ Combine info from multiple sources when needed
- ✅ Admit when information isn't in the docs

**Red Flags:**
- ❌ Making up information not in the docs
- ❌ Citing irrelevant sources
- ❌ Missing obvious information from available docs
- ❌ Contradicting information between sources
- ❌ Overly generic answers when specific info is available
