import streamlit as st

st.set_page_config(
    page_title="CLIF LIGHTHOUSE",
    page_icon="🏥",
)
st.sidebar.image("asset\logo-image-2.png", use_column_width=True )
st.title("WIDE TABLEs for CLIF 📏")
st.markdown('####')

if st.session_state:
    st.success('Your session is configured!', icon="✅")
    st.write("You have entered", st.session_state['azure_connection_string'])
    st.write("You have entered", st.session_state['connection_type'])
else:
    st.warning('Setup data connection before using this tool', icon="⚠️")