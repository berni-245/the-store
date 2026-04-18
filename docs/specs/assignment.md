# Full assignment of CI/CD for Service Deployment and Management
**Technologies:** Jenkins, AWS CodePipeline, GitHub Actions (or similar), Helm

---

## 1. Objective

The objective of this project is to design, implement, and demonstrate a **CI/CD pipeline** for deploying and managing services within a microservices-based application.

The group must:
- Implement a **functional CI/CD solution**
- Demonstrate its behavior in a real environment
- Explain architectural and technical decisions in an oral presentation

---

## 2. Application Context

The target system is an e-commerce platform called **“The Store”**, composed of multiple microservices.

- Source code and documentation are provided
- A deployment script for a **Kubernetes cluster** is included
- This environment should be used as the base for development and testing

---

## 3. Scope of Work (Specific to CI/CD)

You are required to implement a **functional CI/CD solution**

### Allowed technologies
- Jenkins
- CodePipeline
- GitHub Actions or similar
- Helm
---

## 4. General Requirements

### Implementation
- The system must be **fully functional and demonstrable**
- The implementation must match the design proposed in the pre-delivery document (strict requirement)
- Any deviation from the original design may result in failing the project

### Evaluation Criteria
The evaluation will consider:
- Implementation quality
- Architectural decisions
- Oral presentation
- Pre-delivery document
- Final documentation (including “how-to” guide)

---

## 5. Pre-Delivery (Architecture Proposal)

A **PDF document (max. 4 pages)** must be submitted including:

### Required Sections
- **Problem Statement and Context**
- **Solution Design**
- **POC Scope and Use Cases**
- **Architecture Diagram**, including:
    - CIDR blocks
    - IP networks
    - Operating systems
    - Protocols
    - Relevant infrastructure details
- **Alternative Solutions Considered**

### Critical Constraint
- The final implementation **must match exactly** what is defined here
- If not fully implemented → the project must be retaken

### Review Process
- Feedback may require:
    - Additional content
    - Design modifications
- A revised version may be requested (without grade penalty)

---

## 6. Final Delivery

### Oral Presentation
- Maximum duration: **30 minutes**
- Must include:
    - Problem explanation
    - Proposed solution
    - Technologies used
    - Architectural decisions
    - **Live functional demonstration (mandatory)**

---

## 7. Deliverables

The following artifacts must be submitted:

### 7.1 Pre-Delivery Document
- PDF with architecture and design

### 7.2 Presentation
- Slides (PPT or equivalent) used in the oral presentation

### 7.3 Source Code + Documentation
- Hosted in a public repository (e.g., GitHub)
- Must include:
    - Full implementation
    - Configuration files (pipelines, Helm charts, etc.)
    - A **“how-to” guide** explaining:
        - How to set up the system
        - How to run the pipeline
        - How deployments are performed
        - Any prerequisites or dependencies

---

## 8. Constraints and Considerations

- Some technology choices may incur costs (e.g., cloud services)
    - The team assumes responsibility for these costs
    - Cost cannot justify incomplete implementation
    - Thus, it's STRONGLY SUGGESTED to avoid solutions that requires costs

- The solution must be:
    - Technically sound
    - Reproducible
    - Properly documented