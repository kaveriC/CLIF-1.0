import streamlit as st


st.set_page_config(
    page_title="CLIF LIGHTHOUSE",
    page_icon="🏥",
    layout="wide"
)
st.sidebar.image("asset\logo-image-2.png", use_column_width=True )
st.title("CLIF TABLE CHECK-UP 🩺")
st.markdown('####')

if st.session_state:
    st.success('Your session is configured!', icon="✅")
    

    tab1, tab2, tab3,tab4, tab5, tab6,tab7, tab8, tab9,tab10 = st.tabs([
    
    "Categorical Tables",
    "Vitals",
    "Scores",
    "Labs",
    "Microbiology",
    "Respiratory_support",
    "ECMO_MCS",
    "Medication_*",
    "Intake_output",
    "Dialysis"
])

    with tab1:
        st.header("A cat")
        st.image("https://static.streamlit.io/examples/cat.jpg", width=200)

    with tab2:
        st.header("A dog")
        st.image("https://static.streamlit.io/examples/dog.jpg", width=200)

    with tab3:
        st.header("An owl")
        st.image("https://static.streamlit.io/examples/owl.jpg", width=200)








else:
    st.warning('Setup data connection before using this tool', icon="⚠️")