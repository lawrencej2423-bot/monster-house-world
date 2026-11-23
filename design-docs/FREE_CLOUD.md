# FREE CLOUD — Can Faceless get a FREE Windows machine strong enough to finish his Highrise World?

**Question:** Faceless asked for a **free** cloud Windows machine to run Highrise Studio Hub + Unity 2022.3.30f1, controlled from his iPhone, replacing the $37.99/mo Shadow PC from `phone-routes/ROUTE_01_CLOUD_WINDOWS_TO_PHONE.md`. Per `phone-routes/ROUTE_09_TEXT_AUTHORED_PROJECT.md`, Jett authors ~80–90% of the world as text files on his own server — so the cloud machine is only the **finisher**: open the project in Unity → Play → Upload → Publish. That matters: a **CPU-only** VM is slow in Unity but survivable for a finisher; a GPU is *preferred*, not mandatory.
**Researched:** 2026-11-22, against official provider pages (Microsoft Learn / Azure offer terms, Google Cloud Free Program docs) plus provider pricing data. **No signups, no card details, no credentials handled.**

---

## TL;DR

| Route | Cost to him | Card needed? | Windows? | GPU? | Free VM hours at Studio spec* | Verdict |
|---|---|---|---|---|---|---|
| **1. Azure for Students** | **$0** | **No** | ✅ Yes | ❌ Blocked (quota locked at 0, increases refused) | **~265 hrs** (D4s_v5) over **12 months** | ⭐ **WINNER** |
| 2. Azure free account | $0 for 30 days | Yes (verification) | ✅ Yes | ❌ Blocked during trial; unlocks only after upgrading to pay-as-you-go | ~530 hrs inside a 30-day window | Strong backup / stackable after #1 |
| 3. Google Cloud trial → upgrade | $0 credit, but requires becoming a **paid** account | Yes | ❌ Banned on trial; ✅ after upgrade | ❌ Banned on trial; quota request after upgrade | ~675 hrs CPU-only post-upgrade | Works, but "free" only after handing Google a live billing account |
| 4. Kamatera trial | $0 for 30 days | Yes (or $10 refundable prepaid deposit) | ✅ Yes, incl. Windows 10/11 desktop | ❌ No GPU servers offered | Up to ~720 hrs (one server, config ≤ $100/mo) for 30 days | Real, simple, but a hard 30-day cliff |
| 5. Game streaming (GeForce NOW free, Luna) | $0 | — | ❌ | — | 0 | **Ruled out** — see §5 |

\* "Studio spec" = 4 vCPU / 16 GB RAM Windows VM (D4s_v5 class) unless noted. Prices are East US list, Nov 2026; hours are estimates — disks/egress shave a little off.

---

## 1. Azure for Students ⭐ — the lead candidate, verified

Sources: official offer terms (https://azure.microsoft.com/en-gb/pricing/offers/ms-azr-0170p/), Microsoft Learn "What is Azure for Students?", Microsoft Learn Education Hub FAQ, Microsoft Learn quota docs/Q&A.

### What he gets
- **$100 Azure credit, usable over 12 months**, plus select free services.
- **No credit card at sign-up.** This is the only route in this file with no card anywhere in it.
- Credit "can be used within 12 months **on most Azure products**" — Windows VMs are a normal Azure product and are payable from the credit. (Excluded: support plans, Azure DevOps, Marketplace/third-party products, separately-licensed products.)

### Eligibility — read this before promising it works
- Must **affirm he is 18 or older** and a **full-time student** at an **accredited, degree-granting two-year or four-year institution**, and **verify academic status through the institution's email address** (his LA Film School email is exactly the mechanism — sign up with it, click the verification link Microsoft sends there).
- **Not** valid for MOOCs or for-profit professional training courses.
- One subscription per eligible student, non-transferable, and Microsoft warns the offer has a **limited supply of activations** ("while supplies last").
- **Honest risk flag:** if his LAFS program is part-time or a non-degree certificate, verification can fail. If it does, Route 2 (Azure free account) is the fallback and needs no student status. Nothing about his enrollment was assumed — the check happens in step 2 below and costs nothing.

### VM sizes and the GPU question — the decisive part
- **GPU (N-series / NV-series): ❌ effectively blocked.** Microsoft's own quota documentation states it flatly, in multiple places: *"Free Trial and Azure for Students subscriptions aren't eligible for limit or quota increases"* (Azure Kubernetes Service quotas doc, Microsoft Learn; same sentence in the Azure Automation limits doc: *"Free subscriptions including Azure Free Account and Azure for Students aren't eligible for limit or quota changes"*). GPU VM families ship with **quota 0** on these subscriptions, and Microsoft Q&A answers confirm increase requests for GPU families (NV/NC/ND) on Azure for Students are **denied** — the spending cap is locked on. The only fix Microsoft offers is upgrading that subscription to pay-as-you-go, which ends the free ride for GPU purposes.
- **CPU Windows VMs: ✅ allowed.** The realistic target is **Standard_D4s_v5 (4 vCPU / 16 GB)** at **$0.376/hr Windows, East US** → **$100 ≈ 265 hours** of VM time, spread over 12 months however he likes. Stretch option: **B4ms (4 vCPU / 16 GB burstable) at ~$0.182/hr Windows** → **~550 hours**, at burstable-CPU speed (fine for a finisher, sluggish for long Play sessions). D8s_v5 (8/32 GB) is $0.752/hr → ~133 hrs if a session needs more muscle.
- **Gotcha — check quota before building the plan:** student subscriptions also have **policy-enforced region restrictions** (region-access requests are refused too). First portal task after signup: *Subscriptions → Usage + quotas* in **East US** (a region Microsoft Q&A steers students to), confirm the D-family (or B-family) vCPU quota is above zero, *then* deploy. If D shows 0 in his subscription, fall back to the B-family — B-series is the family Microsoft explicitly bundles for students.
- **Unity on a CPU-only VM, honestly:** Unity 2022.3 Editor will install and open a small project on 16 GB RAM with no discrete GPU; expect slow shader compiles, a laggy Scene view over remote desktop, and Play mode at low fidelity. For this project's shape — Jett's text-authored world + a runtime builder script, cloud machine only opens/plays/uploads — that's acceptable. It would NOT be acceptable if he wanted to hand-build scenes in the editor for hours (that's what Shadow's GPU was for).

### Renewal and end-of-offer terms
- **Renewable:** "If you reach the end of your 12 months and are still a student, you can **renew** your Azure for Students offer" by signing up again; Microsoft emails a reminder shortly before the anniversary (Education Hub FAQ, Microsoft Learn). Each renewal is a fresh $100. Unused credit does **not** carry over.
- If the credit runs out early, the subscription is **disabled**; deployed resources are decommissioned if he doesn't upgrade. He has **90 days** after the free subscription ends to upgrade to pay-as-you-go and keep resources. Upgrading is done via Azure Support per the offer terms (the FAQ also describes a portal path).
- Balance is tracked in the Azure Sponsorships portal; monthly invoices may arrive showing usage already covered by credit — **not bills**.

### iPhone control
- Microsoft's **Windows App Mobile** (App Store, free; formerly "Remote Desktop / RD Client") connects from iPhone/iPad to remote PCs and Windows Server — for a plain Azure VM he adds a **PC connection** using the VM's public IP and the VM admin credentials **he creates himself** in the portal.
- **Security gotcha:** do not leave RDP (port 3389) open to the whole internet. In the VM's Network Security Group, restrict inbound 3389 to his home IP, use a strong admin password, and stop the VM from the portal when not in a session (stopping also stops the credit burn — deallocated VMs don't bill compute).

### Exact signup steps (all done by Faceless, on his phone browser)
1. Go to the Azure for Students page (azure.microsoft.com → Free → Students) → **Start free**.
2. Sign in with (or create) a Microsoft account, then **verify academic status with his LA Film School email** — open the verification email in that inbox and click the link.
3. Confirm the subscription "Azure for Students" exists in the portal and the $100 shows in the Sponsorships portal. *(If verification fails → stop, use Route 2.)*
4. Portal → **Create a resource → Virtual Machine**: Windows Server 2022 (or Windows 11 if offered in his region list), size **Standard_D4s_v5**, region **East US**, admin username/password **he invents and keeps**, disk 128 GB Standard SSD. Inbound ports: RDP only, then immediately narrow the NSG rule to his IP.
5. Install **Windows App Mobile** on the iPhone → add PC → VM's public IP → connect.
6. Inside the VM (his session): install Studio Hub from create.highrise.game → it installs Unity **2022.3.30f1** + Studio Package (~30–60 min of downloads) → **he** signs into Unity (free personal license) and his Highrise account → create/open the project Jett syncs in.
7. Discipline rule for every session: **Stop (deallocate) the VM in the portal when done.** ~265 hours is plenty for finishing several worlds — but only if the VM isn't left idling 24/7 (24/7 would burn the whole $100 in ~11 days).

---

## 2. Azure free account — $200 / 30 days, GPU locked until upgrade

Sources: Microsoft Learn "Create free services with Azure free account"; Azure free account offer/FAQ; Microsoft Learn quota docs (same citations as §1).

- **$200 credit for the first 30 days, usable on any service** (except third-party Marketplace purchases), then **12 months of free monthly amounts** of select services, plus always-free tiers. A **credit card IS required** at signup (identity verification; the subscription pauses rather than billing when credit ends, unless he upgrades).
- **The 12-month free VMs are a trap for this project:** the free VM sizes are **B1s / B2pts v2 / B2ats v2 — 1–2 GB RAM class. They cannot run Unity.** Ignore them; only the $200 credit matters here.
- **GPU during the credit window: ❌ blocked the same way as Students.** Free Trial subscriptions aren't eligible for quota increases, and GPU families start at quota 0. The documented path: **upgrade to pay-as-you-go** (portal, keeps any unused credit for the rest of the 30 days and keeps the 12-month free services), *then* request GPU quota (e.g. **NV12ads_A10_v5**, 12 vCPU / 110 GB / A10 slice, **$1.46/hr Windows**) → $200 ≈ **137 GPU hours** if the quota is granted quickly. Quota grants on a brand-new pay-as-you-go account are a request, not a guarantee — Microsoft reviews them, and it can take hours to days.
- **Without upgrading:** D4s_v5 Windows at $0.376/hr → **~530 hours inside a hard 30-day window** (max possible is 720 wall-clock hours). More hours than Students, but compressed into one month and gated behind a card.
- **Gotcha:** if he doesn't upgrade within 30 days / before credit exhaustion, the subscription is disabled and the 12-month free services are lost; upgrading inside the window is what preserves them.
- **Stacking note:** Students (§1) and the free account (§2) are *different offers*. Using the student offer first (12-month runway) and keeping the free account in reserve is the conservative order — but eligibility for the standard free account can be affected by prior Azure offers on the same identity, so don't burn both on day one.

---

## 3. Google Cloud — $300 / 90 days, but Windows and GPUs are banned until you become a paid customer

Source: Google Cloud Free Program docs, "Free Google Cloud features and trial offer" (cloud.google.com / docs.cloud.google.com), read in full.

- **The trial:** $300 Welcome credit, 90/91 days, new customers, **card required for verification but not charged** during the trial. Compute Engine on trial accounts is also capped at **8 concurrent cores**.
- **While the billing account is a Free Trial account, Google's own doc lists what you can't do:**
  - **Add GPUs to VM instances** ❌
  - **Create VM instances based on Windows Server images** ❌ ← this alone kills the trial for Studio Hub
  - Use Google Cloud Marketplace ❌
  - **Request a quota increase** ❌
  - Create VMware Engine resources ❌
- **The upgrade path (verified in the same doc):** *"Although upgrading to a Paid billing account ends your Free Trial, **you keep any unused credit until it expires** [90 days from signup], and you continue to have access to the Free Tier."* Upgrading is one click ("Activate") in the Billing console — but from that moment the account is a **real paid account**: usage beyond the remaining credit bills his card.
- **After upgrading, the realistic sequence:** create a Windows VM (now allowed) → for a GPU, open **IAM & Admin → Quotas**, request GPU quota (e.g. NVIDIA L4 / `GPUS_PER_GPU_FAMILY` / `NVIDIA_L4_GPUS`) in the chosen region → wait. **Realistic timeline:** the request itself is ~10 minutes; approval on an established paid account is often same-day to ~2 business days, but brand-new accounts are routinely told to build billing history first — **treat GPU on GCP as "maybe in a few days, possibly refused," not a plan.**
- **Hours math (post-upgrade, credit still applies):** CPU-only **n2-standard-4 Windows ≈ $0.443/hr** → **~675 hours**; n2-standard-8 Windows ≈ $0.81/hr → ~370 hrs. GPU **g2-standard-8 (L4) + Windows licence ≈ $1.0–1.1/hr** → **~280 hours** *if* quota is granted.
- **Verdict:** the biggest credit pile, and the only route where "free" requires first converting into a paying customer with a live card behind it. Ranked below Azure for this user: more friction, more risk of an accidental real bill, no advantage for a finisher machine.

---

## 4. Kamatera trial + the rest of the field

### Kamatera — 30-day free trial, up to $100 (still offered)
Sources: Kamatera's trial terms as listed on kamatera.com and corroborated in current (Nov 2026) HostAdvice reviews — **flagged: Kamatera's own trial page is the one source in this file summarized via its listings/reviews rather than fetched in full.**
- **Offer:** 30 days, **one cloud server configured however you choose, up to $100 value**, plus 1 TB block storage and 1 TB traffic, full platform access, 24/7 support.
- **Card:** a **valid credit card is required** to activate (no charge during the trial). A prepaid alternative with a **refundable $10 deposit** exists for people who fail card verification, and prepaid accounts still get the free first month.
- **Windows:** full Windows images, including **Windows 10/11 desktop** editions (not just Server) — friendlier for Studio Hub than a Server image. RDP access is a headline feature; connects from the same Windows App Mobile on his iPhone.
- **Spec fit:** a **4 vCPU / 16 GB / 100 GB Windows config lists at ~$97/mo** — i.e., the trial can carry a Studio-spec machine **running 24/7 for the full 30 days (~720 hrs)** inside the $100 cap. **No GPU servers** — CPU-only, same finisher caveat as §1.
- **Gotchas:** one server only; the cliff is total at day 30 (pay or lose the machine); hourly-billed configs must stay under the $100 cap — pick the monthly-priced config and confirm the trial credit covers it before deploying.

### Others, briefly
- **Vultr:** runs real Windows VMs and even cloud GPUs, and new-account promo credits ($100–$300 class) circulate through partner/referral links — but there is **no standing, official free-trial offer** to verify; amounts and expiry (often ~30 days) depend on the specific promo link, and promo credit typically can't be assumed to cover GPU/marketplace items. Legit as a lucky find, not a plan.
- **Akamai/Linode credits:** $100/60-day promos exist — **ruled out: Linode offers no Windows images at all**, and Studio Hub needs Windows or Mac.
- **InstaGame's 100 free credits (≈1 hour):** demo only. Studio Hub + Unity install alone is 30–60 min of downloads before a project even opens — one hour proves the stream works and finishes nothing.
- **Oracle Cloud Always Free:** generous on paper, but the free VMs are Arm/Linux micro instances — **no free Windows**, so no Studio Hub. Ruled out for this job.

## 5. Ruled out in one line each
- **USER HARD RULE (2026-11-22, after Thinkmay):** free workarounds ONLY — no paywall, no credit card, not even $1.12. Do not bring paid/card options back.
- **GitHub Actions Windows runners (new lead, 2026-11-22):** standard runners in PUBLIC repos are free and unlimited; Windows runner = 4 CPU / 16 GB RAM (docs list 14 GB SSD). No card — just a free GitHub account. Not an interactive desktop: Jett drives it by script (workflow installs Unity 2022.3.30f1 + Highrise Studio package, opens/builds the project Jett authored as files). Unproven step: Highrise world Upload normally happens via the Unity editor's Upload button after in-editor Highrise sign-in; a scripted/headless publish path is NOT yet verified. Disk space is the other risk (Unity install is large vs the runner's free space).
- **Kamatera (cancelled by user 2026-11-22):** trial sign-up opened, first step email+password, but trial requires a valid credit card in a later step — user rejected it for that reason. No account was created; the browser task was closed while waiting on the secure entry card, nothing submitted.
- **Thinkmay (checked 2026-11-22, obscure lead — CORRECTED same evening):** Vietnamese cloud-PC service. Its marketing says "free trial," but the verified pricing is **$1.12 for the 3-hour "Experience" plan** (30 credits, once per account) — NOT free. Specs are strong: Xeon 8 vCPU / RTX 3060 Ti 8 GB / 16 GB RAM, Windows 11, full admin, install any software. **Nothing is kept between sessions** — one-shot only (install 30–60 min + open/Play/Upload inside one session); master files stay with Jett, so a wipe loses only time. Servers are Asia-only (Vietnam/Singapore/Jakarta) — latency from LA unverified. The user registered an account himself on 2026-11-22 (email ljaydadonnmusic@gmail.com, phone 502-974-3428); dashboard shows "You don't have a Cloud PC yet" — no plan chosen, no payment made. Payment is wallet top-up; whether a US card is accepted was not verified (public payment page lists bank transfer / payment code, Vietnamese only).
- **InstaGame:** 100 free credits ≈ 1 hour, no card, Google sign-in, full Windows + GPU — too short alone for install+upload.
- **AppOnFly:** ~20-min repeatable no-signup Windows sessions, but volatile and the hosted trial can't properly install custom software — too short/limited for Studio Hub.
- **FreeRDPs.com:** claims lifetime-free RDP, no card, but free tier is ~1–2 GB RAM / no admin, and third-party trust scoring flags it as high-risk (10/100) — do NOT sign into the user's Highrise account on it. Ruled out on account safety.
- **OnWorks:** "Windows" there is a Linux desktop with a Windows theme — cannot run native Windows Studio Hub. Ruled out.
- **Browser.lol (checked 2026-11-22, user suggestion):** a disposable cloud *browser* only — free tier is a Linux container with 2 cores / 2 GB RAM, ~2 hrs active, 2-min inactivity timeout, sessions/downloads wiped on close. No Windows desktop, no installs, no persistence — cannot run Studio Hub/Unity. Ruled out for this job.
- **GeForce NOW (free tier):** a game-streaming library client — it streams games NVIDIA hosts; there is **no installable Windows desktop**, so Studio Hub/Unity can never be installed on it.
- **Amazon Luna:** same shape — streams Luna's game catalog to your screen; **no general-purpose Windows desktop, no software installs.**

---

## 6. Ranked verdict

| Rank | Route | Free hours at Studio spec | Window | Why this rank |
|---|---|---|---|---|
| **1** | **Azure for Students** | **~265 hrs** (D4s_v5 Win) / ~550 hrs (B4ms) | **12 months, renewable yearly while he's a student** | Only route with **no card at all**; Windows allowed; the long window matches a build that happens in sessions, not a sprint. GPU blocked — acceptable because the machine is only the finisher. |
| 2 | Kamatera trial | Up to ~720 hrs (config ≤ $100/mo) | 30 days, hard cliff | Simplest real desktop (Win 10/11), no quota games — but card required and the machine vanishes at day 30 unless he pays. Best if the world must be finished *this month*. |
| 3 | Azure free account | ~530 hrs (D4s_v5 Win) | 30 days | Most Azure hours, card required, same GPU lock; the only free route with a documented path to a real GPU (upgrade → quota request → ~137 hrs of NV12ads_A10_v5) — at the price of becoming pay-as-you-go. |
| 4 | Google Cloud trial → upgrade | ~675 hrs CPU / ~280 hrs GPU *if quota granted* | 90 days (credit clock) | Biggest credit, worst friction: Windows and GPU both banned until he converts to a paid account, and new-account GPU quota is a coin flip. |

**Bottom line:** Yes — a free cloud strong enough to *finish* the world exists, and it's the student offer he already qualifies for on paper. What no free route gives him is a **GPU**; every provider locks GPU quota behind a paid subscription. Given Route 9's text-first build, that's a speed bump (slow Play mode), not a wall.

### Exact first step for the winner
**Faceless, on his iPhone browser (~5 minutes): open the Azure for Students page → "Start free" → sign in → verify with his LA Film School email (click the link Microsoft emails to that inbox).** That single step settles the only open eligibility question. Once the portal shows the "Azure for Students" subscription with $100 credit, the next steps are §1's steps 4–6 (deploy D4s_v5 in East US, narrow the RDP rule to his IP, connect with Windows App Mobile, install Studio Hub) — and Jett's already-written world files sync in from there.

---

## Sources
- Azure for Students offer terms: https://azure.microsoft.com/en-gb/pricing/offers/ms-azr-0170p/
- Azure for Students overview ($100, no card, eligibility): https://learn.microsoft.com/en-us/azure/education-hub/about-azure-for-students and https://azure.microsoft.com/en-ca/resources/students/
- Azure Education Hub FAQ (renewal, exhaustion, 90-day upgrade window): https://learn.microsoft.com/en-us/azure/education-hub/azure-dev-tools-teaching/program-faq
- Quota ineligibility for Free Trial / Students (official Learn docs): https://learn.microsoft.com/ga-ie/azure/aks/quotas-skus-regions ; https://learn.microsoft.com/mt-mt/azure/automation/automation-subscription-limits-faq ; GPU-on-Students denials: https://learn.microsoft.com/en-us/answers/questions/5532921/request-quota-for-nv4as-v4-vm-on-azure-for-student
- Azure free account ($200/30 days, free VM sizes, upgrade keeps credit + 12-mo services): https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/create-free-services ; https://azure.microsoft.com/pricing/offers/ms-azr-0044p
- Azure VM list prices (D4s_v5 Windows $0.376/hr; B4ms Windows ~$0.182/hr; NV12ads_A10_v5 Windows $1.46/hr): Azure Retail Prices data via https://azurehub.org/tools/vm-pricing/Standard_D4s_v5/ and https://azurehub.org/tools/vm-pricing/Standard_NV12ads_A10_v5/ ; NVads A10 v5 specs: https://learn.microsoft.com/azure/virtual-machines/nva10v5-series
- Windows App Mobile (iOS RDP client, formerly RD Client): https://apps.apple.com/us/app/windows-app-mobile/id714464092
- Google Cloud Free Program (trial restrictions list; upgrade keeps credit): https://docs.cloud.google.com/free/docs/free-cloud-features and https://cloud.google.com/free/docs/gcp-free-tier
- Kamatera 30-day / $100 trial terms and Windows desktop images: https://www.kamatera.com (trial page) as corroborated by https://hostadvice.com/hosting-company/kamatera-reviews/ and https://hostadvice.com/hosting-company/kamatera-reviews/kamatera-rdp-review/
- Companion files: `phone-routes/ROUTE_01_CLOUD_WINDOWS_TO_PHONE.md` (Shadow baseline), `phone-routes/ROUTE_09_TEXT_AUTHORED_PROJECT.md` (why CPU-only finishing works), `FEASIBILITY.md`
