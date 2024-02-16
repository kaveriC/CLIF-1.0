import streamlit as st
import time
from clif_check_up import *

st.set_page_config(
    page_title="CLIF LIGHTHOUSE",
    page_icon="🏥",
)
st.sidebar.image("asset\logo-image-2.png", use_column_width=True )
st.title("CLIF LIGHTHOUSE")
st.write("Tool to validate and sanitize clif tables")
st.divider()
st.markdown('####')



def main():
    st.title("Data Source Configuration")

    # Step 1: Ask user for data location
    data_location = st.selectbox("Select your data location", ["Azure Blob", "AWS S3", "Local"])

    # Step 2: Based on the selection, ask for input
    if data_location == "Azure Blob":
        # Step 3: In case of Azure, ask for "connection string"
        azure_connection_string = st.text_input("Enter your Azure Blob connection string", type="password")
        local_data_output_folder_path = st.text_input("Enter your local OUTPUT folder path")
        if azure_connection_string:
            # Step 4: Store in session
            st.session_state['azure_connection_string'] = azure_connection_string
            st.session_state['connection_type']='azure'
            st.session_state['output_path']=local_data_output_folder_path

    elif data_location == "AWS S3":
        # Step 3: In case of AWS, ask for S3 details
        s3_region = st.text_input("Enter your S3 region")
        s3_use_ssl = st.checkbox("Use SSL for S3")
        s3_access_key_id = st.text_input("Enter your S3 Access Key ID")
        s3_secret_access_key = st.text_input("Enter your S3 Secret Access Key", type="password")
        local_data_output_folder_path = st.text_input("Enter your local OUTPUT folder path")
        if s3_region and s3_access_key_id and s3_secret_access_key:
            # Step 4: Store in session
            st.session_state['s3_details'] = {
                'region': s3_region,
                'use_ssl': s3_use_ssl,
                'access_key_id': s3_access_key_id,
                'secret_access_key': s3_secret_access_key
            }
            st.session_state['connection_type']='aws'
            st.session_state['output_path']=local_data_output_folder_path


    elif data_location == "Local":
        # Step 3: In case of Local, ask for folder path
        local_data_folder_path = st.text_input("Enter your local data folder path", type="password")
        local_data_output_folder_path = st.text_input("Enter your local OUTPUT folder path")
        if local_data_folder_path:
            # Step 4: Store in session
            st.session_state['local_data_folder_path'] = local_data_folder_path
            st.session_state['connection_type']='local'
            st.session_state['output_path']=local_data_output_folder_path

    
       
    

if __name__ == "__main__":
    main()

     # Step 5: Notify user of the option chosen and inputs provided
    if st.session_state:
        st.success('Your session is configured!', icon="✅")

    st.markdown('####')  
    st.write("You have entered",checkup())
