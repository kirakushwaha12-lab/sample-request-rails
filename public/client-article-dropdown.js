console.log("CLIENT ARTICLE SCRIPT LOADED");

document.addEventListener("DOMContentLoaded", () => {
    const clientDropdown =
        document.getElementById("ClientCode");

    if (!clientDropdown) {
        console.error("Client Code dropdown not found.");
        return;
    }

    const token =
        localStorage.getItem("token") ||
        localStorage.getItem("authToken") ||
        sessionStorage.getItem("token");

    console.log("TOKEN EXISTS:", !!token);

    if (!token) {
        console.error("Login token not found.");
        return;
    }

    async function loadClients() {
        console.log("FETCHING MY CLIENTS...");

        try {
            const response = await fetch(
                "/api/clients/my-clients",
                {
                    method: "GET",
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            console.log(
                "CLIENT RESPONSE STATUS:",
                response.status
            );

            const data = await response.json();

            console.log("CLIENT API DATA:", data);

            if (!response.ok) {
                throw new Error(
                    data.message || "Failed to load clients"
                );
            }

            const clients = Array.isArray(data)
                ? data
                : data.clients || [];
            console.log(
                "CLIENT CODES:",
                clients.map(client => client.client_code)
            );

            window.allClients = clients;

            const clientCodeDropdown =
                document.getElementById("clientCodeDropdown");

            if (clientCodeDropdown) {
                clientCodeDropdown.innerHTML = "";

                clients.forEach((client) => {
                    const option =
                        document.createElement("div");

                    option.textContent =
                        client.client_code;

                    option.dataset.clientCode =
                        client.client_code;

                    option.addEventListener("click", function () {
                        clientDropdown.value =
                            client.client_code;

                        clientCodeDropdown.style.display =
                            "none";

                        clientDropdown.dispatchEvent(
                            new Event("change")
                        );
                    });

                    clientCodeDropdown.appendChild(option);
                });
            }

        } catch (error) {
            console.error(
                "Client dropdown error:",
                error
            );

            clientDropdown.value = "";
            clientDropdown.placeholder = "Failed to load clients";
        }
    }

    window.loadArticles = async function loadArticles(clientId) {
        const articleInputs = document.querySelectorAll(
            ".article-box .article-no"
        );

        if (articleInputs.length === 0) {
            console.error("Article No input not found.");
            return;
        }

        try {
            console.log("FETCHING ARTICLES FOR CLIENT ID:", clientId);

            const response = await fetch(
                "/api/clients/my-articles",
                {
                    method: "GET",
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            console.log("ARTICLE RESPONSE STATUS:", response.status);

            const data = await response.json();

            console.log("ARTICLES API RESPONSE:", data);

            if (!response.ok) {
                throw new Error(
                    data.message || "Failed to load articles"
                );
            }

            // All articles from API
            window.allArticles = data.articles || [];

            // Only selected client's articles
            window.currentClientArticles =
                window.allArticles.filter(
                    (article) =>
                        Number(article.client_id) ===
                        Number(clientId)
                );

            // Populate the ACTUAL custom dropdown
            articleInputs.forEach((input) => {
                if (!input.value) {
                    input.placeholder = "Select or type Article No.";
                }

                setupArticleDropdown(input);
            });

        } catch (error) {
            console.error(
                "Failed to load articles:",
                error
            );

            articleInputs.forEach((input) => {
                input.value = "";
                input.placeholder =
                    "Failed to load articles";
            });
        }
    };

    window.populateArticleDropdown = function (input) {
        if (!input) {
            return;
        }

        console.log("===== POPULATE DROPDOWN =====");
        console.log("INPUT VALUE:", input.value);

        // Find the visible custom dropdown
        const wrapper =
            input.closest(".custom-input-wrapper");

        const dropdown =
            wrapper?.querySelector(".custom-dropdown");

        console.log("DROPDOWN FOUND:", !!dropdown);

        if (!dropdown) {
            return;
        }

        const allArticles =
            window.currentClientArticles || [];

        if (allArticles.length === 0) {
            return;
        }

        console.log(
            "CURRENT CLIENT ARTICLES:",
            allArticles.map(article => article.article_no)
        );

        // Articles already selected in other Article boxes
        const selectedArticleNumbers = [
            ...document.querySelectorAll(
                ".article-box .article-no"
            )
        ]
            .filter((item) => item !== input)
            .map((item) => item.value.trim())
            .filter(Boolean);

        console.log(
            "SELECTED ARTICLE NUMBERS:",
            selectedArticleNumbers
        );

        // Keep current input's value visible
        const currentValue = input.value.trim();

        // Clear existing visible dropdown
        dropdown.innerHTML = "";

        // Remove articles already selected in other boxes
        const remainingArticles =
            allArticles.filter((article) => {
                const articleNo =
                    String(article.article_no).trim();

                return (
                    !selectedArticleNumbers.includes(articleNo) ||
                    articleNo === currentValue
                );
            });

        console.log(
            "REMAINING ARTICLES:",
            remainingArticles.map(
                article => article.article_no
            )
        );

        // Nothing left
        // Nothing left
        if (remainingArticles.length === 0) {
            const option =
                document.createElement("div");

            option.textContent =
                "No remaining articles";

            option.style.cursor = "default";
            option.style.userSelect = "none";

            dropdown.appendChild(option);

            dropdown.style.display = "block";

            console.log(
                "NO REMAINING ARTICLES ADDED"
            );

            return;
        }

        // Add remaining articles
        remainingArticles.forEach((article) => {
            const option =
                document.createElement("div");

            option.textContent =
                article.article_no;

            option.dataset.articleNo =
                article.article_no;

            option.addEventListener(
                "mousedown",
                (event) => {
                    event.preventDefault();

                    input.value =
                        article.article_no;

                    dropdown.style.display =
                        "none";

                    input.dispatchEvent(
                        new Event("change", {
                            bubbles: true
                        })
                    );
                }
            );

            dropdown.appendChild(option);
        });

        console.log(
            "FINAL DROPDOWN OPTIONS:",
            [...dropdown.children].map(
                option => option.textContent
            )
        );

        dropdown.style.display = "block";
    };

    window.refreshArticleDropdowns = function () {
        document
            .querySelectorAll(".article-box .article-no")
            .forEach((dropdown) => {
                window.populateArticleDropdown(dropdown);
            });
    };


    const clientCodeDropdown =
        document.getElementById("clientCodeDropdown");

    function showClientCodeDropdown() {
        const clients = window.allClients || [];

        clientCodeDropdown.innerHTML = "";

        clients.forEach((client) => {
            const option = document.createElement("div");

            option.textContent = client.client_code;

            option.addEventListener("mousedown", function (event) {
                event.preventDefault();

                clientDropdown.value =
                    client.client_code;

                clientCodeDropdown.style.display =
                    "none";

                clientDropdown.dispatchEvent(
                    new Event("change")
                );
            });

            clientCodeDropdown.appendChild(option);
        });

        clientCodeDropdown.style.display =
            clients.length > 0 ? "block" : "none";
    }

    clientDropdown.addEventListener(
        "focus",
        showClientCodeDropdown
    );

    clientDropdown.addEventListener(
        "click",
        showClientCodeDropdown
    );

    clientDropdown.addEventListener(
        "input",
        function () {
            const searchText =
                this.value.trim().toLowerCase();

            const clients =
                window.allClients || [];

            const filteredClients =
                clients.filter((client) =>
                    String(client.client_code)
                        .toLowerCase()
                        .includes(searchText)
                );

            clientCodeDropdown.innerHTML = "";

            filteredClients.forEach((client) => {
                const option =
                    document.createElement("div");

                option.textContent =
                    client.client_code;

                option.addEventListener(
                    "mousedown",
                    function (event) {
                        event.preventDefault();

                        clientDropdown.value =
                            client.client_code;

                        clientCodeDropdown.style.display =
                            "none";

                        clientDropdown.dispatchEvent(
                            new Event("change")
                        );
                    }
                );

                clientCodeDropdown.appendChild(option);
            });

            clientCodeDropdown.style.display =
                filteredClients.length > 0
                    ? "block"
                    : "none";
        }
    );

    document.addEventListener("click", function (event) {
        if (
            !event.target.closest(".client-code-wrapper")
        ) {
            clientCodeDropdown.style.display =
                "none";
        }
    });

    clientDropdown.addEventListener("change", function () {
        const selectedClientCode = this.value.trim();

        const selectedClient = (window.allClients || []).find(
            (client) =>
                String(client.client_code) ===
                String(selectedClientCode)
        );

        const selectedClientId = selectedClient
            ? selectedClient.id
            : "";

        console.log("CLIENT SELECTED ID:", selectedClientId);

        const articleDropdowns =
            document.querySelectorAll(
                ".article-box .article-no"
            );

        if (!selectedClientId) {
            articleDropdowns.forEach((input) => {
                input.value = "";
                input.placeholder = "Select Article No.";
            });
            return;
        }

        loadArticles(selectedClientId);
    }
    );

    window.setupArticleDropdown = function (input) { 
        const wrapper = input.closest(".custom-input-wrapper");

        if (!wrapper) return;

        const dropdown = wrapper.querySelector(".custom-dropdown");

        if (!dropdown) return;

        // Prevent duplicate event listeners
        if (input.dataset.dropdownSetup === "true") {
            return;
        }

        input.dataset.dropdownSetup = "true";

        function showAllArticles() {
            if (
                typeof window.populateArticleDropdown === "function"
            ) {
                window.populateArticleDropdown(input);
            }



            dropdown.style.display =
                dropdown.children.length > 0
                    ? "block"
                    : "none";
        }

        input.addEventListener("focus", function () {
            showAllArticles();
        });

        input.addEventListener("click", function () {
            showAllArticles();
        });

        input.addEventListener("input", function () {
            const searchText =
                this.value.trim().toLowerCase();

            Array.from(dropdown.children).forEach((option) => {
                option.style.display =
                    option.textContent
                        .toLowerCase()
                        .includes(searchText)
                        ? "block"
                        : "none";
            });

            dropdown.style.display = "block";
        });
    }

    //article no change

    const articlesContainer =
        document.getElementById("articlesContainer");

    if (articlesContainer) {
        articlesContainer.addEventListener(
            "change",
            function (event) {
                if (
                    !event.target.matches(
                        ".article-no"
                    )
                ) {
                    return;
                }

                const articleInput =
                    event.target;

                const selectedArticleNo =
                    articleInput.value;

                const article =
                    (window.allArticles || []).find(
                        (item) =>
                            String(item.article_no) ===
                            String(selectedArticleNo)
                    );

                if (!article) {
                    const articleBox =
                        articleInput.closest(".article-box");

                    if (articleBox) {
                        articleBox
                            .querySelectorAll("input, textarea")
                            .forEach((field) => {
                                if (
                                    field !== articleInput &&
                                    field.type !== "file"
                                ) {
                                    field.value = "";
                                }
                            });

                        articleBox
                            .querySelectorAll("select")
                            .forEach((field) => {
                                field.selectedIndex = 0;
                            });

                        articleBox
                            .querySelectorAll("img")
                            .forEach((img) => {
                                img.removeAttribute("src");
                                img.style.display = "none";
                            });
                    }

                    return;
                }


                const articleBox =
                    articleInput.closest(
                        ".article-box"
                    );

                if (!articleBox) {
                    return;
                }

                const articleId =
                    Number(
                        articleBox.dataset.articleId
                    );

                console.log(
                    "SELECTED ARTICLE:",
                    article
                );

                /*
                   Existing function from your main JS.
                   This fills all fields and images.
                */

                if (
                    typeof loadArticleData ===
                    "function"
                ) {
                    loadArticleData(
                        articleBox,
                        articleId,
                        article
                    );

                    const articleInputs =
                        document.querySelectorAll(
                            ".article-box .article-no"
                        );

                    const nextEmptyInput =
                        Array.from(articleInputs).find(
                            (input) => !input.value.trim()
                        );

                    if (nextEmptyInput) {
                        window.populateArticleDropdown(
                            nextEmptyInput
                        );
                    }

                } else {
                    console.error(
                        "loadArticleData function not found."
                    );
                }
            }
        );
    } else {
        console.error(
            "articlesContainer not found."
        );
    }

    loadClients();
});