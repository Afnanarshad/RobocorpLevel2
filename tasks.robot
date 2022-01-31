*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    OperatingSystem
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    #${Orders URL}=    Get input from user
    ${Orders URL}=    Get URL from vault
    Open the intranet website
    ${orders}=    Get orders    ${Orders URL}
    FOR    ${row}    IN    @{orders}
        Order a robot    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    [Teardown]    Close Browser
    Zip files of the receipts
    #configure such that it required input for CSV URL
    #Read The URL from the Valut file
    
*** Keywords ***
Get URL from vault
    ${information}=    Get Secret    info
    [Return]    ${information}[URL]

Get input from user
    Add text input    search    label=Please provide the URL
    ${response}=    Run dialog
    [Return]    ${response.search}

Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
  
Get orders
    [Arguments]    ${Orders URL}
    Download    ${Orders URL}    overwrite=True
    Wait Until Created    orders.csv
    ${orders}=    Read table from CSV    orders.csv    header=True
    Close Workbook
    [Return]    ${orders}
 
Order a robot
    [Arguments]    ${row}
    Click Element If Visible    //button[@class="btn btn-dark"]
      
    Does Page Contain Element    id:head
    Select From List By Index    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button When Visible    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Keyword Succeeds    10x    2s    Submit Order
   

Submit Order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${Order Number}
    ${order_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_html}    ${OUTPUT_DIR}${/}order_${Order Number}.pdf
    [Return]    order_${Order Number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order Number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}order_${Order Number}.PNG
    [Return]    order_${Order Number}.PNG

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}${screenshot}

    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}${pdf}    append=True
    Remove File    ${OUTPUT_DIR}${/}${screenshot}

Go to order another robot
    Click Button When Visible    id:order-another
    
Zip files of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    orders.zip    include=order_*.pdf 