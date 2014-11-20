CREATE OR REPLACE PACKAGE BODY xxwsh400009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400009C(body)
 * Description      : �o�׈˗��m�F�\
 * MD.050           : �o�׈˗�       T_MD050_BPO_401
 * MD.070           : �o�׈˗��m�F�\ T_MD070_BPO_40J
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XML�f�[�^�ϊ�
 *  pro_get_cus_option     �֘A�f�[�^�擾
 *  insert_xml_plsql_table XML�f�[�^�i�[
 *  prc_initialize         �O����(�S���ҏ�񒊏o)
 *  prc_get_report_data    ���׃f�[�^�擾
 *  create_xml             XML�f�[�^�쐬
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Masanobu Kimura  �V�K�쐬
 *  2008/06/10    1.1   �Γn  ���a       �w�b�_�u�o�͓��t�v�̏�����ύX
 *  2008/06/13    1.2   �Γn  ���a       �s��Ή�
 *  2008/06/23    1.3   �Γn  ���a       ST�s��Ή�#106
 *  2008/07/01    1.4   ���c  ����       ST�s��Ή�#331 ���i�敪�͓��̓p�����[�^����擾
 *  2008/07/02    1.5   Satoshi Yunba    �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/03    1.6   �Ŗ�  ���\       ST�s��Ή�#344�357�406�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- �Ώۃf�[�^�Ȃ���O
  data_not_found exception;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                  CONSTANT VARCHAR2(20) := 'XXWSH400009C';
                                        -- �p�b�P�[�W��
  -- ���[ID
  gc_report_id                 CONSTANT VARCHAR2(12) := 'XXWSH400009T';
                                        -- ���[ID
  -- �v���t�@�C��
  gv_prf_wei_u                 CONSTANT VARCHAR2(50) := 'XXWSH_WEIGHT_UOM';
                                        -- XXWSH:�o�׏d�ʒP��
  gv_prf_cap_u                 CONSTANT VARCHAR2(50) := 'XXWSH_CAPACITY_UOM';
                                        -- XXWSH:�o�חe�ϒP��
  gv_prf_prod_class_code       CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV_SECURITY';
                                        -- XXCMN:���i�敪
  -- �G���[�R�[�h
  gv_application_wsh           CONSTANT VARCHAR2(5)  := 'XXWSH';
                                        -- �A�v���P�[�V����
  gv_application_cmn           CONSTANT VARCHAR2(5)  := 'XXCMN';
                                        -- �A�v���P�[�V����
  gv_err_pro                   CONSTANT VARCHAR2(20) := 'APP-XXCMN-10002';
                                        -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_err_nodata                CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';
                                        -- �o�׈˗��m�F���Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  -- �g�[�N��
  gv_tkn_prof_name             CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  -- �g�[�N�������b�Z�[�W
  gv_tkn_msg_wei_u             CONSTANT VARCHAR2(20) := 'XXWSH:�o�׏d�ʒP��';
  gv_tkn_msg_cap_u             CONSTANT VARCHAR2(20) := 'XXWSH:�o�חe�ϒP��';
  gv_tkn_msg_prod_class_code   CONSTANT VARCHAR2(20) := 'XXCMN:���i�敪';
  -- �^�O�^�C�v
  gc_tag_type_data             CONSTANT VARCHAR2(1)  := 'D' ;
                                        -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
  -- �N�C�b�N�R�[�h
  gv_tr_status                 CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
                                        --�X�e�[�^�X
  gv_shipping_class            CONSTANT VARCHAR2(21) := 'XXWSH_SHIPPING_CLASS';
                                        --�˗��敪
  gv_lg_confirm_req_class      CONSTANT VARCHAR2(27) := 'XXWSH_LG_CONFIRM_REQ_CLASS';
                                        --�����敪
  -- �R�[�h
  gv_order_category_code       CONSTANT VARCHAR2(5)  := 'ORDER';
  gv_shipping_shikyu_class     CONSTANT VARCHAR2(1)  := '1';
  gv_yes                       CONSTANT VARCHAR2(1)  := 'Y';
-- 2008/07/03 ST�s��Ή�#344 Start
  gv_cancel                    CONSTANT VARCHAR2(2)  := '99';
-- 2008/07/03 ST�s��Ή�#344 End
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format             CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gc_char_d_format2            CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      iv_head_sales_branch       VARCHAR2(4),       --   1.�Ǌ����_
      iv_input_sales_branch      VARCHAR2(4),       --   2.���͋��_
      iv_deliver_to              VARCHAR2(9),       --   3.�z����
      iv_deliver_from            VARCHAR2(4),       --   4.�o�׌�
      iv_ship_date_from          VARCHAR2(10),      --   5.�o�ɓ�From
      iv_ship_date_to            VARCHAR2(10),      --   6.�o�ɓ�To
      iv_arrival_date_from       VARCHAR2(10),      --   7.����From
      iv_arrival_date_to         VARCHAR2(10),      --   8.����To
      iv_order_type_id           VARCHAR2(20),      --   9.�o�Ɍ`��
      iv_request_no              VARCHAR2(12),      --   10.�˗�No.
      iv_req_status              VARCHAR2(20),      --   11.�o�׈˗��X�e�[�^�X
      iv_confirm_request_class   VARCHAR2(20),      --   12.�����S���m�F�˗��敪
      iv_prod_class              VARCHAR2(20)       --   13.���i�敪 2008/07/01 ST�s��Ή�#331
    ) ;
--
  -- �f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
     request_no                  xxwsh_order_headers_all.request_no%TYPE
                                                    -- �˗�No
     ,customer_code              xxwsh_order_headers_all.customer_code%TYPE
                                                    -- �ڋq�R�[�h
     ,party_short_name           xxcmn_cust_accounts2_v.party_short_name%TYPE
                                                    -- �ڋq
     --,address                    xxcmn_cust_acct_sites2_v.address_line1%TYPE
     ,address                     VARCHAR2(60)
                                                    -- �z����Z��
     ,address_line1              xxwsh_order_headers_all.head_sales_branch%TYPE
                                                    -- �Ǌ����_�R�[�h
     ,address_line_name          xxcmn_cust_accounts2_v.party_short_name%TYPE
                                                    -- �Ǌ����_
     ,deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE
                                                    -- �z����R�[�h
     ,party_site_full_name       xxcmn_cust_acct_sites2_v.party_site_full_name%TYPE
                                                    -- �z����
     ,mixed_no                   xxwsh_order_headers_all.mixed_no%TYPE
                                                    -- ���ڌ�No
     ,cust_po_number             xxwsh_order_headers_all.cust_po_number%TYPE
                                                    -- �ڋq�����ԍ�
     ,schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE
                                                    -- �o�ɓ�
     ,schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE
                                                    -- ����
     ,arrival_time_from          xxwsh_order_headers_all.arrival_time_from%TYPE
                                                    -- ���Ԏw��ifrom�j
     ,arrival_time_to            xxwsh_order_headers_all.arrival_time_to%TYPE
                                                    -- ���Ԏw��ito�j
     ,order_type_id              xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
                                                    -- �o�Ɍ`��
     ,meaning1                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- �˗��敪
     ,ship_method_meaning        xxwsh_ship_method2_v.ship_method_meaning%TYPE
                                                    -- �z���敪
     ,collected_pallet_qty       xxwsh_order_headers_all.collected_pallet_qty%TYPE
                                                    -- �p���b�g�������
     ,meaning2                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- �X�e�[�^�X
     ,meaning3                   xxcmn_lookup_values_v.meaning%TYPE
                                                    -- �����敪
     ,shipping_instructions      xxwsh_order_headers_all.shipping_instructions%TYPE
                                                    -- �E�v
     ,deliver_from               xxwsh_order_headers_all.deliver_from%TYPE
                                                    -- �o�׌��R�[�h
     ,description                xxcmn_item_locations_v.description%TYPE
                                                    -- �o�׌�
     ,request_item_code          xxwsh_order_lines_all.request_item_code%TYPE
                                                    -- �i�ڃR�[�h
     ,item_short_name            xxcmn_item_mst_v.item_short_name%TYPE
                                                    -- �i��
     ,pallet_quantity            xxwsh_order_lines_all.pallet_quantity%TYPE
                                                    -- �p���b�g����
     ,layer_quantity             xxwsh_order_lines_all.layer_quantity%TYPE
                                                    -- �p���b�g�i��
     ,case_quantity              xxwsh_order_lines_all.case_quantity%TYPE
                                                    -- �P�[�X��
     ,quantity                   xxwsh_order_lines_all.quantity%TYPE
                                                    -- ����
     ,item_um                    xxcmn_item_mst_v.item_um%TYPE
                                                    -- �����i�P�ʁj
     ,num_of_cases               xxcmn_item_mst_v.num_of_cases%TYPE
                                                    -- ����
     ,weight                     xxwsh_order_lines_all.weight%TYPE
                                                    -- ���v�d��/���v�e��
     ,weight_capacity_class      xxcmn_item_mst_v.weight_capacity_class%TYPE
                                                    -- ���v�d��/���v�e�ρi�P�ʁj
     ,pallet_sum_quantity        xxwsh_order_headers_all.pallet_sum_quantity%TYPE
                                                    -- ��گč��v����
     ,sum_weight                 xxwsh_order_headers_all.sum_weight%TYPE
                                                    -- ���d��/���e��
     ,sum_weight_capacity_class  VARCHAR2(10)
                                                    -- ���d��/���e�ρi�P�ʁj
     ,loading_efficiency_weight  xxwsh_order_headers_all.loading_efficiency_weight%TYPE
                                                    -- �ύڗ�
    ) ;

  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_department_code           VARCHAR2(10);      -- �S������
  gv_department_name           VARCHAR2(14);      -- �S����
--
  gv_name_wei_u                VARCHAR2(20);      -- �o�׏d�ʒP��
  gv_name_cap_u                VARCHAR2(20);      -- �o�חe�ϒP��
  gv_name_prod_class_code      VARCHAR2(20);      -- ���i�敪
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- �v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
  --
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
  --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : �֘A�f�[�^�擾
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    ------------------------------------------
    -- �v���t�@�C������o�׏d�ʒP�ʎ擾
    ------------------------------------------
    gv_name_wei_u := SUBSTRB(FND_PROFILE.VALUE(gv_prf_wei_u), 1, 2);
    -- �擾�G���[��
    IF (gv_name_wei_u IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_wsh  -- 'XXWSH'
                                                     ,gv_err_pro          -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_prof_name    -- �g�[�N��
                                                     ,gv_tkn_msg_wei_u    -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- �v���t�@�C������o�חe�ϒP�ʎ擾
    ------------------------------------------
    gv_name_cap_u := SUBSTRB(FND_PROFILE.VALUE(gv_prf_cap_u), 1, 2);
    -- �擾�G���[��
    IF (gv_name_cap_u IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_wsh  -- 'XXWSH'
                                                     ,gv_err_pro          -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_prof_name    -- �g�[�N��
                                                     ,gv_tkn_msg_cap_u    -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- �v���t�@�C�����珤�i�敪�擾
    ------------------------------------------
    --���i�敪�̓v���t�@�C������ł͂Ȃ����̓p�����[�^����擾����
    -- 2008/07/01 ST�s��Ή�#331
    --
    --gv_name_prod_class_code := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod_class_code), 1, 2);
    ---- �擾�G���[��
    --IF (gv_name_prod_class_code IS NULL) THEN
    --  lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_cmn  -- 'XXCMN'
    --                                                 ,gv_err_pro          -- �v���t�@�C���擾�G���[
    --                                                 ,gv_tkn_prof_name    -- �g�[�N��
    --                                                 ,gv_tkn_msg_prod_class_code     -- ���b�Z�[�W
    --                                                )
    --                                                ,1
    --                                                ,5000);
    --  RAISE global_api_expt;
    --END IF;
    --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XML�f�[�^�i�[
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY XML_DATA,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- �v���O������
  --
  --
  --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
  --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  --
  --###########################  �Œ蕔 END   ####################################
  --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
  --
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;
  --
    -- *** ���[�J���E�J�[�\�� ***
  --
    -- *** ���[�J���E���R�[�h ***
  --
  BEGIN
--
    ln_count := iox_xml_data.COUNT + 1 ;
    iox_xml_data( ln_count ).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data( ln_count ).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value), '99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data( ln_count ).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value), '9999990.90');
    ELSE
      iox_xml_data( ln_count ).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data( ln_count ).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(�S���ҏ�񒊏o)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt     NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code     VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_main_data
      (
        iv_head_sales_branch         VARCHAR2,      --   1.�Ǌ����_
        iv_input_sales_branch        VARCHAR2,      --   2.���͋��_
        iv_deliver_to                VARCHAR2,      --   3.�z����
        iv_deliver_from              VARCHAR2,      --   4.�o�׌�
        iv_ship_date_from            VARCHAR2,      --   5.�o�ɓ�From
        iv_ship_date_to              VARCHAR2,      --   6.�o�ɓ�To
        iv_arrival_date_from         VARCHAR2,      --   7.����From
        iv_arrival_date_to           VARCHAR2,      --   8.����To
        iv_order_type_id             VARCHAR2,      --   9.�o�Ɍ`��
        iv_request_no                VARCHAR2,      --   10.�˗�No.
        iv_req_status                VARCHAR2,      --   11.�o�׈˗��X�e�[�^�X
        iv_confirm_request_class     VARCHAR2,      --   12.�����S���m�F�˗��敪
        iv_prod_class                VARCHAR2       --   13.���i�敪  2008/07/01 ST�s��Ή�#331
      )
    IS
      SELECT xoha.request_no                                            -- �˗�no
            ,xoha.customer_code                                         -- �ڋq�R�[�h
            ,xca2v.party_short_name                                     -- �ڋq
            ,xcas2v.address_line1 || xcas2v.address_line2               -- �z����Z��
            ,xoha.head_sales_branch                                     -- �Ǌ����_�R�[�h
            ,xca2v2.party_short_name                                    -- �Ǌ����_
            ,xoha.deliver_to                                            -- �z����R�[�h
            ,xcas2v.party_site_full_name                                -- �z����
            ,xoha.mixed_no                                              -- ���ڌ�no
            ,xoha.cust_po_number                                        -- �ڋq�����ԍ�
            ,xoha.schedule_ship_date                                    -- �o�ɓ�
            ,xoha.schedule_arrival_date                                 -- ����
            ,xoha.arrival_time_from                                     -- ���Ԏw��ifrom�j
            ,xoha.arrival_time_to                                       -- ���Ԏw��ito�j
            ,xott2v.transaction_type_name                               -- �o�Ɍ`��
            ,xlv2v.meaning                                              -- �˗��敪
            ,xsm2v.ship_method_meaning                                  -- �z���敪
            ,xoha.collected_pallet_qty                                  -- �p���b�g�������
            ,xlv2v2.meaning                                             -- �X�e�[�^�X
            ,xlv2v3.meaning                                             -- �����敪
            ,xoha.shipping_instructions                                 -- �E�v
            ,xoha.deliver_from                                          -- �o�׌��R�[�h
            ,xil2v.description                                          -- �o�׌�
            ,xola.request_item_code                                     -- �i�ڃR�[�h
            ,xim2v.item_short_name                                      -- �i��
            ,xola.pallet_quantity                                       -- �p���b�g����
            ,xola.layer_quantity                                        -- �p���b�g�i��
            ,xola.case_quantity                                         -- �P�[�X��
            ,CASE
              WHEN xim2v.conv_unit IS NULL THEN xola.quantity
              ELSE xola.quantity / CASE
                                    WHEN xim2v.num_of_cases IS NULL THEN '1'
                                    WHEN xim2v.num_of_cases = '0'   THEN '1'
                                    ELSE                                 xim2v.num_of_cases
                                   END
             END                                                        -- ����
            ,CASE
              WHEN xim2v.conv_unit IS NULL THEN xim2v.item_um
              ELSE                              xim2v.conv_unit
             END                                                        -- �����i�P�ʁj
            ,NVL(xim2v.num_of_cases, '-')                               -- ����
            ,CASE 
              WHEN xsm2v.small_amount_class = '1' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1' THEN xola.weight
                                WHEN xoha.weight_capacity_class = '2' THEN xola.capacity
                              END 
              WHEN xsm2v.small_amount_class = '0' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1'
                                 THEN xola.pallet_weight + xola.weight
                                WHEN xoha.weight_capacity_class = '2'
                                 THEN xola.pallet_weight + xola.capacity
                              END
             END                                                        -- ���v�d��/���v�e��
            ,CASE 
              WHEN xim2v.weight_capacity_class = '1' THEN gv_name_wei_u
              WHEN xim2v.weight_capacity_class = '2' THEN gv_name_cap_u
             END                                                        -- ���v�d��/���v�e��(�P��)
            ,xoha.pallet_sum_quantity                                   -- ��گč��v����
            ,CASE 
              WHEN xsm2v.small_amount_class = '1' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1' THEN xoha.sum_weight
                                WHEN xoha.weight_capacity_class = '2' THEN xoha.sum_capacity
                              END 
              WHEN xsm2v.small_amount_class = '0' THEN
                              CASE 
                                WHEN xoha.weight_capacity_class = '1'
                                 THEN xola.pallet_weight + xoha.sum_weight
                                WHEN xoha.weight_capacity_class = '2'
                                 THEN xola.pallet_weight + xoha.sum_capacity
                              END
             END                                                        -- ���d��/���e��
            ,CASE 
              WHEN xoha.weight_capacity_class = '1' THEN gv_name_wei_u
              WHEN xoha.weight_capacity_class = '2' THEN gv_name_cap_u
             END                                                        -- ���d��/���e�ρi�P�ʁj
            ,CASE 
              WHEN xoha.weight_capacity_class = '1' THEN xoha.loading_efficiency_weight
              WHEN xoha.weight_capacity_class = '2' THEN xoha.loading_efficiency_capacity
             END                                                        -- �ύڗ�
       FROM xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all          xola                        -- �󒍖��׃A�h�I��
          ,xxcmn_cust_acct_sites2_v       xcas2v                      -- �ڋq�T�C�g���VIEW2
          ,xxcmn_cust_accounts2_v         xca2v                       -- �ڋq���VIEW2(�ڋq���)
          ,xxcmn_cust_accounts2_v         xca2v2                      -- �ڋq���VIEW2(�Ǌ����_)
          ,xxcmn_item_mst2_v              xim2v                       -- OPM�i�ڃA�h�I���}�X�^
-- 2008/07/04 ST�s��Ή�#406 Start
--          ,xxcmn_item_categories4_v       xic4v                       -- �i�ڃJ�e�S���}�X�^
-- 2008/07/04 ST�s��Ή�#406 End
          ,xxcmn_lookup_values2_v         xlv2v                       -- �N�C�b�N�R�[�h(�˗��敪)
          ,xxcmn_lookup_values2_v         xlv2v2                      -- �N�C�b�N�R�[�h(�X�e�[�^�X)
          ,xxcmn_lookup_values2_v         xlv2v3                      -- �N�C�b�N�R�[�h(�����敪)
          ,xxcmn_item_locations2_v        xil2v                       -- OPM�ۊǏꏊ�}�X�^
          ,xxwsh_oe_transaction_types2_v  xott2v                      -- �󒍃^�C�v
          ,xxwsh_ship_method2_v           xsm2v                       -- �z���敪���VIEW2
      WHERE xott2v.order_category_code       = gv_order_category_code
                                       -- �󒍃^�C�v.�󒍃J�e�S�����u�󒍁v
        AND xott2v.shipping_shikyu_class     = gv_shipping_shikyu_class
                                       -- �󒍃^�C�v.�o�׎x���敪���u�o�׈˗��v
        AND xott2v.transaction_type_id       = xoha.order_type_id
                                       -- �󒍃^�C�v.�󒍃^�C�vID���󒍃w�b�_�A�h�I��.�󒍃^�C�vID
        AND xoha.head_sales_branch           = NVL(iv_head_sales_branch, xoha.head_sales_branch)
                                       -- �󒍃w�b�_�A�h�I��.�Ǌ����_���p�����[�^.�Ǌ����_
        AND xoha.input_sales_branch          = iv_input_sales_branch
                                       -- �󒍃w�b�_�A�h�I��.���͋��_���p�����[�^.���͋��_
        AND xoha.deliver_to                  = NVL(iv_deliver_to, xoha.deliver_to)
                                       -- �󒍃w�b�_�A�h�I��.�o�א恁�p�����[�^.�z���悩��
        AND xoha.deliver_from                = NVL(iv_deliver_from, xoha.deliver_from)
                                       -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ���p�����[�^.�o�׌�
        AND xoha.schedule_ship_date          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �󒍃w�b�_�A�h�I��.�o�ח\������p�����[�^.�o�ɓ�From
        AND xoha.schedule_ship_date          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_to,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �󒍃w�b�_�A�h�I��.�o�ח\������p�����[�^.�o�ɓ�To
        AND xoha.schedule_arrival_date       >= 
        NVL(FND_DATE.STRING_TO_DATE(iv_arrival_date_from,gc_char_d_format),
                                                                       xoha.schedule_arrival_date)
                                       -- �󒍃w�b�_�A�h�I��.���ח\������p�����[�^.����From
        AND xoha.schedule_arrival_date       <= 
        NVL(FND_DATE.STRING_TO_DATE(iv_arrival_date_to,gc_char_d_format),
                                                                       xoha.schedule_arrival_date)
                                       -- �󒍃w�b�_�A�h�I��.���ח\������p�����[�^.����To
        AND xoha.order_type_id               = NVL(iv_order_type_id, xoha.order_type_id)
                                       -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���p�����[�^.�o�Ɍ`��                                                                       
        AND xoha.request_no                  = NVL(iv_request_no, xoha.request_no)
                                       -- �󒍃w�b�_�A�h�I��.�˗�No���p�����[�^.�˗�No
        AND xoha.req_status                  = xlv2v2.lookup_code
                                -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���N�C�b�N�R�[�h(�X�e�[�^�X).�R�[�h
        AND xlv2v2.lookup_type               = gv_tr_status
                                       -- �N�C�b�N�R�[�h(�X�e�[�^�X).�^�C�v���e�o�׈˗��X�e�[�^�X�f
        AND xoha.req_status                  = NVL(iv_req_status, xoha.req_status)
                                -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���p�����[�^.�o�׈˗��X�e�[�^�X
        AND xoha.latest_external_flag        = gv_yes
                                       -- �󒍃w�b�_�A�h�I��.�ŐV�t���O���eY�f
        AND xoha.confirm_request_class       = 
            NVL(iv_confirm_request_class, xoha.confirm_request_class)
                      -- �󒍃w�b�_�A�h�I��.�����S���m�F�˗��敪���p�����[�^.�����S���m�F�˗��敪
        AND xoha.confirm_request_class       = xlv2v3.lookup_code
                      -- �󒍃w�b�_�A�h�I��.�����S���m�F�˗��敪���N�C�b�N�R�[�h(�����敪).�R�[�h
        AND xlv2v3.lookup_type               = gv_lg_confirm_req_class
                      -- �N�C�b�N�R�[�h(�����敪).�^�C�v�������敪
        AND xoha.deliver_from_id             = xil2v.inventory_location_id
                                       -- �󒍃w�b�_�A�h�I��.�o�׌�ID��OPM�ۊǏꏊ�}�X�^.�ۊǒIID
        AND xoha.deliver_to_id               = xcas2v.party_site_id
                      -- �󒍃w�b�_�A�h�I��.�o�א�ID���ڋq�T�C�g���VIEW2.�p�[�e�B�T�C�gID
        AND xcas2v.start_date_active         <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq�T�C�g���VIEW2.�K�p�J�n�����p�����[�^.�o�ɓ�From
        AND (xcas2v.end_date_active          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq�T�C�g���VIEW2.�K�p�I�������p�����[�^.�o�ɓ�From
            OR xcas2v.end_date_active        IS NULL)
                                       -- �ڋq�T�C�g���VIEW2.�K�p�I���� = NULL
        AND xoha.head_sales_branch           = xca2v2.party_number
                      -- �󒍃w�b�_�A�h�I��.�Ǌ����_���ڋq���VIEW2(�Ǌ����_).�g�D�ԍ�
        AND xca2v2.start_date_active         <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq���VIEW2(�Ǌ����_).�K�p�J�n�����p�����[�^.�o�ɓ�From
        AND (xca2v2.end_date_active          >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq���VIEW2(�Ǌ����_).�K�p�I�������p�����[�^.�o�ɓ�From
            OR xca2v2.end_date_active        IS NULL)
                                       -- �ڋq���VIEW2(�Ǌ����_).�K�p�I���� = NULL
        AND xoha.customer_id                 = xca2v.party_id
                      -- �󒍃w�b�_�A�h�I��.�ڋqID���ڋq���VIEW2(�ڋq���).�p�[�e�BID
        AND xca2v.start_date_active          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq���VIEW2(�ڋq���).�K�p�J�n�����p�����[�^.�o�ɓ�From
        AND (xca2v.end_date_active           >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- �ڋq���VIEW2(�ڋq���).�K�p�I�������p�����[�^.�o�ɓ�From
            OR xca2v.end_date_active         IS NULL)
                                       -- �ڋq���VIEW2(�ڋq���).�K�p�I���� = NULL
        AND xoha.order_header_id             = xola.order_header_id
            -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID���󒍖��׃A�h�I��.�󒍃w�b�_�A�h�I��ID
        AND xola.request_item_code           = xim2v.item_no
                                       -- �󒍖��׃A�h�I��.�˗��i�ځ�OPM�i�ڃ}�X�^.�i�ڃR�[�h
-- 2008/07/04 ST�s��Ή�#406 Start
--        AND xim2v.item_id                    = xic4v.item_id
                                       -- OPM�i�ڃ}�X�^.�i��ID��OPM�i�ڃJ�e�S���}�X�^.�i��ID
        --AND xic4v.prod_class_code            = gv_name_prod_class_code  -- 2008/07/01 ST�s��Ή�#331
--        AND xic4v.prod_class_code            = iv_prod_class              -- 2008/07/01 ST�s��Ή�#331
        AND xoha.prod_class                  = iv_prod_class
                       -- �󒍃w�b�_�A�h�I��.���i�敪���v���t�@�C���i���i�敪�j:1=���[�t,2=�h�����N
-- 2008/07/04 ST�s��Ή�#406 End
            -- �i�ڃJ�e�S���}�X�^. ���i�敪���v���t�@�C���i���i�敪�j:1=���[�t,2=�h�����N
        AND xim2v.start_date_active          <= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- OPM�i�ڃA�h�I���}�X�^.�K�p�J�n�����p�����[�^.�o�ɓ�From
        AND (xim2v.end_date_active           >= 
            NVL(FND_DATE.STRING_TO_DATE(iv_ship_date_from,gc_char_d_format),
                                                                          xoha.schedule_ship_date)
                                       -- OPM�i�ڃA�h�I���}�X�^.�K�p�I�������p�����[�^.�o�ɓ�From
            OR xim2v.end_date_active         IS NULL)
                                       -- OPM�i�ڃA�h�I���}�X�^.�K�p�I���� = NULL
        AND xlv2v.lookup_type                = gv_shipping_class
                                       -- �N�C�b�N�R�[�h(�˗��敪).�^�C�v���o�׋敪
        AND xlv2v.attribute5                 = xott2v.transaction_type_name
                      -- �N�C�b�N�R�[�h(�˗��敪)�DDFF5(�󒍃^�C�v)���󒍃^�C�v.�󒍃^�C�v
-- 2008/07/04 ST�s��Ή�#406 Start
--        AND xlv2v.attribute4(+)              = xca2v.customer_class_code
--            -- �N�C�b�N�R�[�h(�˗��敪).�ڋq�敪(DFF)(+) ���ڋq���VIEW2(�ڋq���)�D�ڋq�敪
        AND NVL(xlv2v.attribute4, xca2v.customer_class_code) = xca2v.customer_class_code
            -- �N�C�b�N�R�[�h(�˗��敪).�ڋq�敪(DFF)���ڋq���VIEW2(�ڋq���)�D�ڋq�敪
-- 2008/07/04 SST�s��Ή�#406 End
        AND xoha.shipping_method_code        = xsm2v.ship_method_code
                      -- �󒍃w�b�_�A�h�I��.�z���敪=�z���敪���VIEW.�z���敪�R�[�h
-- 2008/07/03 ST�s��Ή�#357 Start
        AND xoha.req_status                  <> gv_cancel
                                       -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X <> ���
-- 2008/07/03 ST�s��Ή�#357 End
-- 2008/07/03 ST�s��Ή�#344 Start
--      ORDER BY xoha.request_no         -- �˗�no
--               ,xola.order_line_number -- ���הԍ�
      ORDER BY xca2v2.party_short_name -- �Ǌ����_
               ,xoha.request_no        -- �˗�no
-- 2008/07/03 ST�s��Ή�#344 End
               ,xola.order_line_number -- ���הԍ�
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data
      (
        ir_param.iv_head_sales_branch         -- �Ǌ����_
       ,ir_param.iv_input_sales_branch        -- ���͋��_
       ,ir_param.iv_deliver_to                -- �z����
       ,ir_param.iv_deliver_from              -- �o�׌�
       ,ir_param.iv_ship_date_from            -- �o�ɓ�From
       ,ir_param.iv_ship_date_to              -- �o�ɓ�To
       ,ir_param.iv_arrival_date_from         -- ����From
       ,ir_param.iv_arrival_date_to           -- ����To
       ,ir_param.iv_order_type_id             -- �o�Ɍ`��
       ,ir_param.iv_request_no                -- �˗�No.
       ,ir_param.iv_req_status                -- �o�׈˗��X�e�[�^�X
       ,ir_param.iv_confirm_request_class     -- �����S���m�F�˗��敪
       ,ir_param.iv_prod_class                -- ���i�敪  2008/07/01 ST�s��Ή�#331
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    IF ( ot_data_rec.COUNT=0 ) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application_cmn      -- 'XXCMN'
                                                     ,gv_err_nodata
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE data_not_found;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
--
  EXCEPTION
      -- *** �o�׈˗��m�F�\���Ώۃf�[�^�Ȃ� �x��***
    WHEN data_not_found THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XML�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE create_xml (
    iox_xml_data IN OUT     NOCOPY XML_DATA,
    ir_param     IN         rec_param_data, -- 01.���R�[�h  �F�p�����[�^
    ov_errbuf    OUT        VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT        VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT        VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000);
    -- �V�X�e�����t
    ld_now_date             DATE DEFAULT SYSDATE;
    -- �O��˗�No.
    pre_req_no              xxwsh_order_headers_all.request_no%TYPE DEFAULT '*';
-- 2008/07/03 ST�s��Ή�#344 Start
    -- �O��Ǌ����_
    pre_add_l_name          xxcmn_cust_accounts2_v.party_short_name%TYPE DEFAULT '*';
-- 2008/07/03 ST�s��Ή�#344 End
    -- �擾���R�[�h�\  
    lt_main_data            tab_data_type_dtl ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
-- *** ���[�J���E��O���� ***
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => lt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( lt_main_data.COUNT = 0 ) THEN
      --�f�[�^�O���[�v���J�n�^�O�Z�b�g
      insert_xml_plsql_table(iox_xml_data, 'g_irai', NULL, 'T', 'C');
      --�f�[�^�Z�b�g�i�w�b�_�j
      insert_xml_plsql_table(iox_xml_data, 'msg', 
             xxcmn_common_pkg.get_msg( gv_application_cmn, gv_err_nodata ), 'D', 'C');
      --�f�[�^�O���[�v���I���^�O�Z�b�g
      insert_xml_plsql_table(iox_xml_data, '/g_irai', NULL, 'T', 'C');
--
      lv_retcode := gv_status_warn;
--
    -- *** ���[�J���E���R�[�h ***
--
    ELSE
--
      <<lg_irai_info>>
      FOR get_user_rec IN 1..lt_main_data.COUNT LOOP
--
        IF ( pre_req_no <> lt_main_data(get_user_rec).request_no ) THEN
--
          IF ( get_user_rec <> 1 ) THEN
            --�f�[�^�O���[�v���I���^�O�Z�b�g
            insert_xml_plsql_table(iox_xml_data, '/lg_mei', NULL, 'T', 'C');
--
            --�f�[�^�Z�b�g(�v)
            insert_xml_plsql_table(iox_xml_data, 'sum_palette', 
                                    lt_main_data(get_user_rec -1).pallet_sum_quantity,'D','C');
            insert_xml_plsql_table(iox_xml_data, 'sum_weight', 
                                    lt_main_data(get_user_rec -1).sum_weight, 'D', 'C');
            insert_xml_plsql_table(iox_xml_data, 'unit_sum2', 
                                    lt_main_data(get_user_rec -1).sum_weight_capacity_class, 'D', 'C');
            insert_xml_plsql_table(iox_xml_data, 'carry_rate', 
                                    lt_main_data(get_user_rec -1).loading_efficiency_weight, 'D', 'C');
--
            --�f�[�^�O���[�v���I���^�O�Z�b�g
            insert_xml_plsql_table(iox_xml_data, '/g_irai',NULL,'T','C');
-- 2008/07/03 ST�s��Ή�#344 Start
            IF ( pre_add_l_name <> lt_main_data(get_user_rec).address_line_name ) THEN
              --�f�[�^�O���[�v���I���^�O�Z�b�g
              insert_xml_plsql_table(iox_xml_data, '/lg_irai_info',NULL,'T','C');
--
              --�f�[�^�O���[�v���J�n�^�O�Z�b�g
              insert_xml_plsql_table(iox_xml_data, 'lg_irai_info', NULL, 'T', 'C');
--
            END IF;
-- 2008/07/03 ST�s��Ή�#344 End
          END IF;
--
          --�f�[�^�O���[�v���J�n�^�O�Z�b�g
          insert_xml_plsql_table(iox_xml_data, 'g_irai', NULL, 'T', 'C');
--
          --�f�[�^�Z�b�g�i�w�b�_�j
          insert_xml_plsql_table(iox_xml_data, 'tyohyo_id', gc_report_id, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'exec_time', 
                                       TO_CHAR(ld_now_date, gc_char_d_format2), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'post' ,gv_department_code, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'name', gv_department_name, 'D', 'C');
--
          --�f�[�^�Z�b�g(��)
          insert_xml_plsql_table(iox_xml_data, 'req_no', 
                                  lt_main_data(get_user_rec).request_no, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'client_code', 
                                  lt_main_data(get_user_rec).customer_code, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'client_name', 
                                  lt_main_data(get_user_rec).party_short_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_address', 
                                  lt_main_data(get_user_rec).address, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'control_code', 
                                  lt_main_data(get_user_rec).address_line1, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'control_name', 
                                  lt_main_data(get_user_rec).address_line_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_code', 
                                  lt_main_data(get_user_rec).deliver_to, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_name', 
                                  lt_main_data(get_user_rec).party_site_full_name, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'mix_no', 
                                  lt_main_data(get_user_rec).mixed_no, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'order_no', 
                                  lt_main_data(get_user_rec).cust_po_number, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'ship_day', 
             TO_CHAR(lt_main_data(get_user_rec).schedule_ship_date, gc_char_d_format), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'arrive_day', 
             TO_CHAR(lt_main_data(get_user_rec).schedule_arrival_date,
                                                                    gc_char_d_format), 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'from_time', 
                                  lt_main_data(get_user_rec).arrival_time_from, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'to_time', 
                                  lt_main_data(get_user_rec).arrival_time_to, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'ship_form', 
                                  lt_main_data(get_user_rec).order_type_id, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'req_division', 
                                  lt_main_data(get_user_rec).meaning1, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'delivery_division', 
                                  lt_main_data(get_user_rec).ship_method_meaning, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'collect_palette', 
                                  lt_main_data(get_user_rec).collected_pallet_qty, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'status', 
                                  lt_main_data(get_user_rec).meaning2, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'pd_division', 
                                  lt_main_data(get_user_rec).meaning3, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'abstract', 
                                  lt_main_data(get_user_rec).shipping_instructions, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'shipment_code', 
                                  lt_main_data(get_user_rec).deliver_from, 'D', 'C');
          insert_xml_plsql_table(iox_xml_data, 'shipment_name', 
                                  lt_main_data(get_user_rec).description, 'D', 'C');
          --�f�[�^�O���[�v���J�n�^�O�Z�b�g
          insert_xml_plsql_table(iox_xml_data, 'lg_mei', NULL, 'T', 'C');
--
          pre_req_no      := lt_main_data(get_user_rec).request_no;
-- 2008/07/03 ST�s��Ή�#344 Start
          pre_add_l_name      := lt_main_data(get_user_rec).address_line_name;
-- 2008/07/03 ST�s��Ή�#344 End
--
        END IF;
--
        --�f�[�^�O���[�v���J�n�^�O�Z�b�g
        insert_xml_plsql_table(iox_xml_data, 'g_mei' , NULL, 'T', 'C');
        --�f�[�^�Z�b�g(�E)
        insert_xml_plsql_table(iox_xml_data, 'list_code', 
                                lt_main_data(get_user_rec).request_item_code, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'list_name', 
                                lt_main_data(get_user_rec).item_short_name, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'num_palette', 
                                lt_main_data(get_user_rec).pallet_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'steps_palette', 
                                lt_main_data(get_user_rec).layer_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'num_case', 
                                lt_main_data(get_user_rec).case_quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'sum', 
                                lt_main_data(get_user_rec).quantity, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'unit_sum1', 
                                lt_main_data(get_user_rec).item_um, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'in_num', 
                                lt_main_data(get_user_rec).num_of_cases, 'D', 'C');
        insert_xml_plsql_table(iox_xml_data, 'total_weight', 
-- 2008/07/03 ST�s��Ή�#344 Start
--                                lt_main_data(get_user_rec).weight, 'D', 'C');
                                CEIL(TRUNC(lt_main_data(get_user_rec).weight, 1)), 'D', 'C');
-- 2008/07/03 ST�s��Ή�#344 End
        insert_xml_plsql_table(iox_xml_data, 'unit_total', 
                                lt_main_data(get_user_rec).weight_capacity_class, 'D', 'C');
--
        --�f�[�^�O���[�v���I���^�O�Z�b�g
        insert_xml_plsql_table(iox_xml_data, '/g_mei', NULL, 'T', 'C');
--
      END LOOP lg_irai_info;
--
      --�f�[�^�O���[�v���I���^�O�Z�b�g
      insert_xml_plsql_table(iox_xml_data, '/lg_mei', NULL, 'T', 'C');
--
      --�f�[�^�Z�b�g(�v)
      insert_xml_plsql_table(iox_xml_data, 'sum_palette', 
                              lt_main_data(lt_main_data.COUNT).pallet_sum_quantity,'D','C');
      insert_xml_plsql_table(iox_xml_data, 'sum_weight', 
-- 2008/07/03 ST�s��Ή�#344 Start
--                              lt_main_data(lt_main_data.COUNT).sum_weight, 'D', 'C');
                             CEIL(TRUNC(lt_main_data(lt_main_data.COUNT).sum_weight, 1)), 'D', 'C');
-- 2008/07/03 ST�s��Ή�#344 End
      insert_xml_plsql_table(iox_xml_data, 'unit_sum2', 
                              lt_main_data(lt_main_data.COUNT).sum_weight_capacity_class, 'D', 'C');
      insert_xml_plsql_table(iox_xml_data, 'carry_rate', 
                              lt_main_data(lt_main_data.COUNT).loading_efficiency_weight, 'D', 'C');
--
      --�f�[�^�O���[�v���I���^�O�Z�b�g
      insert_xml_plsql_table(iox_xml_data, '/g_irai',NULL,'T','C');
--
    END IF ;
   -- ==================================================
   -- �I���X�e�[�^�X�ݒ�
   -- ==================================================
    ov_retcode := lv_retcode;
--  
  EXCEPTION
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END create_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_head_sales_branch       IN  VARCHAR2,      --   1.�Ǌ����_
    iv_input_sales_branch      IN  VARCHAR2,      --   2.���͋��_
    iv_deliver_to              IN  VARCHAR2,      --   3.�z����
    iv_deliver_from            IN  VARCHAR2,      --   4.�o�׌�
    iv_ship_date_from          IN  VARCHAR2,      --   5.�o�ɓ�From
    iv_ship_date_to            IN  VARCHAR2,      --   6.�o�ɓ�To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.����From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.����To
    iv_order_type_id           IN  VARCHAR2,      --   9.�o�Ɍ`��
    iv_request_no              IN  VARCHAR2,      --   10.�˗�No.
    iv_req_status              IN  VARCHAR2,      --   11.�o�׈˗��X�e�[�^�X
    iv_confirm_request_class   IN  VARCHAR2,      --   12.�����S���m�F�˗��敪
    iv_prod_class              IN  VARCHAR2,      --   13.���i�敪  2008/07/01 ST�s��Ή�#331
    ov_errbuf                  OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lr_param_rec     rec_param_data ;          -- �p�����[�^��n���p
--
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- �p�����[�^�i�[
    lr_param_rec.iv_head_sales_branch     := iv_head_sales_branch;      -- 1.�Ǌ����_
    lr_param_rec.iv_input_sales_branch    := iv_input_sales_branch;     -- 2.���͋��_
    lr_param_rec.iv_deliver_to            := iv_deliver_to;             -- 3.�z����
    lr_param_rec.iv_deliver_from          := iv_deliver_from;           -- 4.�o�׌�
    lr_param_rec.iv_ship_date_from        := iv_ship_date_from;         -- 5.�o�ɓ�From
    lr_param_rec.iv_ship_date_to          := iv_ship_date_to;           -- 6.�o�ɓ�To
    lr_param_rec.iv_arrival_date_from     := iv_arrival_date_from;      -- 7.����From
    lr_param_rec.iv_arrival_date_to       := iv_arrival_date_to;        -- 8.����To
    lr_param_rec.iv_order_type_id         := iv_order_type_id;          -- 9.�o�Ɍ`��
    lr_param_rec.iv_request_no            := iv_request_no;             -- 10.�˗�No.
    lr_param_rec.iv_req_status            := iv_req_status;             -- 11.�o�׈˗��X�e�[�^�X
    lr_param_rec.iv_confirm_request_class := iv_confirm_request_class;  -- 12.�����S���m�F�˗��敪
    lr_param_rec.iv_prod_class            := iv_prod_class;             -- 13.���i�敪  2008/07/01 ST�s��Ή�#331
--
    -- =====================================================
    --  �֘A�f�[�^�擾
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- �O����(�S���ҏ�񒊏o)
    -- =====================================================
    prc_initialize
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- XML�f�[�^(Temp)�쐬
    -- ===============================================
    
    create_xml(
      xml_data_table
      ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
      ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- ==================================================
    -- �w�l�k�o��(C-4)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_irai_info>' ) ;

--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    --XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := convert_into_xml
                        (
                          iv_name   => xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_loop ;
    
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_irai_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;

--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                     OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_head_sales_branch       IN  VARCHAR2,      --   1.�Ǌ����_
    iv_input_sales_branch      IN  VARCHAR2,      --   2.���͋��_
    iv_deliver_to              IN  VARCHAR2,      --   3.�z����
    iv_deliver_from            IN  VARCHAR2,      --   4.�o�׌�
    iv_ship_date_from          IN  VARCHAR2,      --   5.�o�ɓ�From
    iv_ship_date_to            IN  VARCHAR2,      --   6.�o�ɓ�To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.����From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.����To
    iv_order_type_id           IN  VARCHAR2,      --   9.�o�Ɍ`��
    iv_request_no              IN  VARCHAR2,      --   10.�˗�No.
    iv_req_status              IN  VARCHAR2,      --   11.�o�׈˗��X�e�[�^�X
    iv_confirm_request_class   IN  VARCHAR2,      --   12.�����S���m�F�˗��敪
    iv_prod_class              IN  VARCHAR2       --   13.���i�敪 2008/07/01 ST�s��Ή�#331
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXWSH400009c.main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_head_sales_branch     => iv_head_sales_branch,     --   1.�Ǌ����_
      iv_input_sales_branch    => iv_input_sales_branch,    --   2.���͋��_
      iv_deliver_to            => iv_deliver_to,            --   3.�z����
      iv_deliver_from          => iv_deliver_from,          --   4.�o�׌�
      iv_ship_date_from        => iv_ship_date_from,        --   5.�o�ɓ�From
      iv_ship_date_to          => iv_ship_date_to,          --   6.�o�ɓ�To
      iv_arrival_date_from     => iv_arrival_date_from,     --   7.����From
      iv_arrival_date_to       => iv_arrival_date_to,       --   8.����To
      iv_order_type_id         => iv_order_type_id,         --   9.�o�Ɍ`��
      iv_request_no            => iv_request_no,            --   10.�˗�No.
      iv_req_status            => iv_req_status,            --   11.�o�׈˗��X�e�[�^�X
      iv_confirm_request_class => iv_confirm_request_class, --   12.�����S���m�F�˗��敪
      iv_prod_class            => iv_prod_class,            --   13.���i�敪 2008/07/01 ST�s��Ή�#331
      ov_errbuf                => lv_errbuf,      --   �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,     --   ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh400009c;
/
