<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>所有權人防詐業務查詢結果</title>
    <style>
        body {
            font-family: Arial, "Microsoft JhengHei", sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        .search-form {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .search-form div {
            margin-bottom: 10px;
        }
        label {
            display: inline-block;
            width: 120px;
            font-weight: bold;
        }
        input[type="text"] {
            padding: 8px;
            width: 250px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        button {
            padding: 8px 15px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background-color: #45a049;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px 15px;
            border: 1px solid #ddd;
            text-align: center;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .status {
            font-weight: bold;
        }
        .status-yes {
            color: #4CAF50;
        }
        .status-no {
            color: #f44336;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>所有權人防詐業務查詢結果</h1>
        
        <div class="search-form">
            <form method="post" action="">
                <div>
                    <label for="searchType">查詢方式：</label>
                    <input type="radio" name="searchType" id="idSearch" value="id" checked> 
                    <label for="idSearch" style="width: auto;">身分字號</label>
                    <input type="radio" name="searchType" id="phoneSearch" value="phone"> 
                    <label for="phoneSearch" style="width: auto;">電話號碼</label>
                </div>
                <div>
                    <label for="searchValue">查詢值：</label>
                    <input type="text" name="searchValue" id="searchValue" required>
                    <button type="submit">查詢</button>
                </div>
            </form>
        </div>
        
        <%
        String searchType = request.getParameter("searchType");
        String searchValue = request.getParameter("searchValue");
        
        if (searchValue != null && !searchValue.trim().isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            // 用來存儲查詢結果的Map
            Map<String, Map<String, String>> results = new HashMap<>();
            
            // 初始化結果
            results.put("地籍異動即時通", new HashMap<>());
            results.put("指定送達處所", new HashMap<>());
            results.put("第二類謄本住址隱匿", new HashMap<>());
            
            try {
                // 資料庫連線設定
                Class.forName("oracle.jdbc.driver.OracleDriver");
                conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:ORCL", "username", "password");
                
                // 依照查詢方式執行不同的SQL
                if ("id".equals(searchType)) {
                    // 查詢地籍異動即時通 (以身分字號)
                    pstmt = conn.prepareStatement("SELECT lidn, mobile, mobile2 FROM sms_userinfo_m WHERE lidn = ?");
                    pstmt.setString(1, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("地籍異動即時通");
                        resultData.put("id", rs.getString("lidn"));
                        String phone = rs.getString("mobile");
                        if (rs.getString("mobile2") != null && !rs.getString("mobile2").trim().isEmpty()) {
                            phone += ", " + rs.getString("mobile2");
                        }
                        resultData.put("phone", phone);
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("地籍異動即時通").put("status", "未申辦");
                    }
                    
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    
                    // 查詢指定送達處所 (以身分字號)
                    pstmt = conn.prepareStatement("SELECT cl04, cl09 FROM sclaam WHERE cl04 = ?");
                    pstmt.setString(1, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("指定送達處所");
                        resultData.put("id", rs.getString("cl04"));
                        resultData.put("phone", rs.getString("cl09"));
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("指定送達處所").put("status", "未申辦");
                    }
                    
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    
                    // 查詢第二類謄本住址隱匿 (以身分字號)
                    pstmt = conn.prepareStatement("SELECT cp09, cpmtel FROM scpuad WHERE cp09 = ?");
                    pstmt.setString(1, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("第二類謄本住址隱匿");
                        resultData.put("id", rs.getString("cp09"));
                        resultData.put("phone", rs.getString("cpmtel"));
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("第二類謄本住址隱匿").put("status", "未申辦");
                    }
                    
                } else if ("phone".equals(searchType)) {
                    // 查詢地籍異動即時通 (以電話號碼)
                    pstmt = conn.prepareStatement("SELECT lidn, mobile, mobile2 FROM sms_userinfo_m WHERE mobile = ? OR mobile2 = ?");
                    pstmt.setString(1, searchValue);
                    pstmt.setString(2, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("地籍異動即時通");
                        resultData.put("id", rs.getString("lidn"));
                        String phone = rs.getString("mobile");
                        if (rs.getString("mobile2") != null && !rs.getString("mobile2").trim().isEmpty()) {
                            phone += ", " + rs.getString("mobile2");
                        }
                        resultData.put("phone", phone);
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("地籍異動即時通").put("status", "未申辦");
                    }
                    
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    
                    // 查詢指定送達處所 (以電話號碼)
                    pstmt = conn.prepareStatement("SELECT cl04, cl09 FROM sclaam WHERE cl09 = ?");
                    pstmt.setString(1, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("指定送達處所");
                        resultData.put("id", rs.getString("cl04"));
                        resultData.put("phone", rs.getString("cl09"));
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("指定送達處所").put("status", "未申辦");
                    }
                    
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    
                    // 查詢第二類謄本住址隱匿 (以電話號碼)
                    pstmt = conn.prepareStatement("SELECT cp09, cpmtel FROM scpuad WHERE cpmtel = ?");
                    pstmt.setString(1, searchValue);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        Map<String, String> resultData = results.get("第二類謄本住址隱匿");
                        resultData.put("id", rs.getString("cp09"));
                        resultData.put("phone", rs.getString("cpmtel"));
                        resultData.put("status", "已申辦");
                    } else {
                        results.get("第二類謄本住址隱匿").put("status", "未申辦");
                    }
                }
        %>
        
        <h2>查詢結果</h2>
        <table>
            <tr>
                <th>業務項目</th>
                <th>身分字號</th>
                <th>申辦狀態</th>
                <th>連絡電話</th>
            </tr>
            <% for (String business : results.keySet()) { 
                Map<String, String> data = results.get(business);
                String status = data.get("status");
                String statusClass = "已申辦".equals(status) ? "status-yes" : "status-no";
            %>
            <tr>
                <td><%= business %></td>
                <td><%= data.get("id") != null ? data.get("id") : "-" %></td>
                <td class="status <%= statusClass %>"><%= status %></td>
                <td><%= data.get("phone") != null ? data.get("phone") : "-" %></td>
            </tr>
            <% } %>
        </table>
        
        <% 
            } catch (Exception e) {
                out.println("<p style='color: red; font-weight: bold;'>查詢發生錯誤: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { }
                try { if (pstmt != null) pstmt.close(); } catch (Exception e) { }
                try { if (conn != null) conn.close(); } catch (Exception e) { }
            }
        }
        %>
    </div>
    
    <script>
        // 表單驗證
        document.querySelector('form').addEventListener('submit', function(e) {
            var searchValue = document.getElementById('searchValue').value.trim();
            var searchType = document.querySelector('input[name="searchType"]:checked').value;
            
            if (searchValue === '') {
                alert('請輸入查詢值');
                e.preventDefault();
                return;
            }
            
            if (searchType === 'id') {
                // 簡單的身分證字號驗證 (10碼)
                if (searchValue.length !== 10) {
                    alert('身分字號應為10碼');
                    e.preventDefault();
                    return;
                }
            } else if (searchType === 'phone') {
                // 簡單的電話號碼驗證
                if (!/^\d+$/.test(searchValue) || searchValue.length < 8) {
                    alert('請輸入有效的電話號碼');
                    e.preventDefault();
                    return;
                }
            }
        });
    </script>
</body>
</html>
