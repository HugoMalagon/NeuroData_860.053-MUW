***
# Processing and Interpretation of Neuroscience Data

**Course Information – First 4 Lessons**

Dear Students,

Here is some information essential for the first 4 lessons of the **Processing and Interpretation of Neuroscience Data** course.

The newest versions of the code can be found on GitHub:

- [GitHub repository](https://github.com/HugoMalagon/NeuroData_860.053-MUW)

***

## Important — To Do Prior to the First Lecture

### Windows and Linux Users — Virtual Machine

We kindly request all students to install **Oracle VirtualBox**, a free software compatible with most x86/x64 CPUs:

- [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)

For guidance on using VirtualBox, please refer to the following resources:

- [Official Manual](https://www.virtualbox.org/manual/)
- [Configuring a Virtual Machine for Local Testing](https://kb.hosting.com/docs/configuring-a-virtual-machine-for-local-testing)
- [YouTube Guide](https://www.youtube.com/watch?v=nvdnQX9UkMY)

Additionally, please download the prepared Virtual Machine (approx. 10 GB, ensure at least 20 GB free space):

- [VM Download Link](https://filesender.aco.net/?s=download&token=100542ef-1282-4bce-94da-dd02ac8f0934)
*NOTE: Link valid untill 26.11.2025*
Once VirtualBox is installed and the files are downloaded, open VirtualBox and **import the OVA file**.
Helpful guide: [How to Import OVA to VirtualBox](https://www.youtube.com/watch?v=PJdsjpZmMMo)

*Password for VM is the same as the username.*
Please check if the VM starts; troubleshooting will be available at the beginning of class.

***

### Mac Users

1. Verify your processor type.
    - If it is **x86**, follow the same Virtual Machine setup as above.
    - If it is **ARM (e.g., M1 or M2)**, VirtualBox will not function. Instead:

#### Steps for ARM (M1/M2) Macs

1. Install **R version 4.5.1** and **RStudio**:
    - [R 4.5.1 for macOS (ARM)](https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-4.5.1-arm64.pkg)
    - [RStudio 2025.09.1-401](https://download1.rstudio.org/electron/macos/RStudio-2025.09.1-401.dmg)
    - [Video Guide](https://www.youtube.com/watch?v=I5WIMX4LK8M)
2. Download data instead of the Virtual Machine:
    - [Data Link](https://filesender.aco.net/?s=download&token=d56276eb-978c-4697-9886-1131af5064fe)
    - *NOTE: Link valid untill 14.11.2025*
3. Unpack the data.
4. Open **Processing_Interpretation_Data_macos.Rproj** in RStudio.
5. In the RStudio console, type:

```r
renv::repair()
```

If you get an error that **renv** is not found, install it first:

```r
install.packages("renv")
renv::repair()
```

*If issues persist, please come 15 minutes earlier before class for troubleshooting.*

**Important:** Download the newest version of `*.Rmd` files from GitHub before class.

***

### Advanced Linux Users

If you prefer a lightweight setup:

1. Install **R version 4.5.1** and **RStudio**.
2. Download the packed lectures:
    - [Linux Data Link](https://filesender.aco.net/?s=download&token=aa4dae03-f1c2-49be-a0a5-745d07e4a5f7)
    - *NOTE: Link valid untill 14.11.2025*
3. Unpack the data.
4. Open **Processing_Interpretation_Data_linux.Rproj**.
5. In RStudio, run:

```r
renv::restore()
```

If necessary:

```r
install.packages("renv")
```

Additional Linux libraries may need installation; follow console prompts.

***

### Advanced R Users

For those comfortable managing R environments manually:

1. Install **R version 4.5.1** and **RStudio**.
2. Download all lesson `.Rmd` files and the `renv.lock` file into your R project.
3. Install dependencies with:

```r
install.packages("renv")
renv::restore()
```


***

## Additional Materials

Please review the additional links and cheat sheets provided within the VM package.

***

## Lectures Overview

### 21.10

- Introduction to R
- Practical examples: descriptive statistics, t-tests
- Visual analytics with base plots


### 28.10

- Introduction to bulk sequencing and analysis methods
- Dimensional reduction: PCA and UMAP
- Clustering methods: k-means, k-NN


### 4.11

- Introduction to Seurat
- Preprocessing single-cell RNA-seq data


### 11.11

- Clustering in Seurat
- Differential Expression Gene (DEG) interpretation

***

## Additional Learning Resources

### RStudio Usage

- [General Introduction](https://www.youtube.com/watch?v=eA6kf4yJXGw&list=WL&index=26&t=332s)
- [Basics of RStudio](https://www.youtube.com/watch?v=FY8BISK5DpM)
- [Inspecting Data](https://choonghyunryu.github.io/dlookr/)
- [DataExplorer Library](https://cran.r-project.org/web/packages/DataExplorer/vignettes/dataexplorer-intro.html#qq-plot)
- [Creating Tables](https://www.danieldsjoberg.com/gtsummary/)


### ggplot2 in R

- [Datacamp Tutorial](https://www.youtube.com/watch?v=YxKr2a-Y1WE&list=PLjgj6kdf_snaBCTJEi53DvRVgOuVbzyku)
- [Hadley Wickham Talk](https://www.youtube.com/watch?v=ZdPNBF6GWBw)


### Tidyverse

- [General Introduction](https://www.youtube.com/watch?v=KsBBRHAgAhM)
- [Dplyr Basics](https://www.youtube.com/watch?v=Bg4qxVNaDck)
- [Data Wrangling in Dplyr](https://www.youtube.com/watch?v=XcK4chr2jws)
- [Tidyverse Teaching Intro](https://youtube.com/watch?v=FV5mPG1uLJk&t=37s&pp=ygUSdGVhY2hpbmcgdGlkeXZlcnNl)


### General Statistics

- [Introductory Statistics](https://www.youtube.com/watch?v=dYJLUvo0Q6g)
- [Variable Selection](https://www.youtube.com/watch?v=XMZ_0aloVAc&list=PL6Gy8EsbrMF-lsnMywDYt73yrzm5HaGtG)


### Dimensional Reduction

- [Eigenvectors Explained](https://www.youtube.com/watch?v=9CT0jnem4vM&t=18s)
- [Eigenvectors \& Eigenvalues](https://www.youtube.com/watch?v=JtcNe--fsyA&t=5s)
- [t-SNE Basics](https://www.youtube.com/watch?v=Bl85EfTiGj0)
- [t-SNE Explained](https://www.youtube.com/watch?v=NEaUSP4YerM&index=7)
- [PCA Overview](https://www.youtube.com/watch?v=FgakZw6K1QQ)
- [PCA Math](https://www.youtube.com/watch?v=S51bTyIwxFs&t=909s)
- [PCA Standardization](https://www.youtube.com/watch?v=dh8aTKXPKlU&t=601s)
- [PCA Interpretation](https://www.youtube.com/watch?v=BiuwDI_BbWw)
- [UMAP Mathematics](https://www.youtube.com/watch?v=jth4kEvJ3P8)


### Clustering

- [k-Means Clustering](https://www.youtube.com/watch?v=4E_DFMt60rc)
- [k-Nearest Neighbors](https://www.youtube.com/watch?v=48RqX4HTtCE)


### Seurat

- [Basics of Seurat](https://www.youtube.com/watch?v=G3Cg7vGpctg)
- [Seurat Objects Explained](https://biostatsquid.com/seurat-objects-explained)

***
