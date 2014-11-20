CREATE OR REPLACE PACKAGE BODY xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(body)
 * Description      : �d�����ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_360)
 *                  : �L���x�����[Issue1.0(T_MD070_BPO_36E)
 * Version          : 1.15
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                      Description
 * -------------------------- ------------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(vendor_code)
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(atr_code)
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(E-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(E-3)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(E-4)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/17    1.0   Y.Majikina       �V�K�쐬
 *  2008/05/12    1.1   Y.Majikina       ����ԕi�A�����Ȃ��ԕi���̑����v�l��
 *                                       �}�C�i�X���|����悤�C��
 *                                       �����Ȃ��d����ԕi�̏ꍇ�A����ԕi���т̊��Z������
 *                                       �擾����悤�C��
 *  2008/05/13    1.2   Y.Majikina       �i�ڂ��Ƃɕi�ڌv���\������Ȃ��_���C��
 *                                       �f�[�^�ɂ���āAYY/MM/DD�AYY/M/D�̂悤�ȏ����ŏo�͂����
 *                                       �_���C��
 *  2008/05/14    1.3   Y.Majikina       �S�������A�S���Җ��̍ő咷������ǉ�
 *                                       �Z�L�����e�B�̏������C��
 *  2008/05/23    1.4   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/23    1.5   Y.Majikina       �Z�L�����e�B�敪�Q�Ń��O�C�������Ƃ���SQL�G���[�ɂȂ�_��
 *                                       �C��
 *  2008/05/26    1.6   R.Tomoyose       ��������d����ԕi���A�P���͎���ԕi���уA�h�I�����擾
 *  2008/05/29    1.7   T.Ikehara        �v�̏o���׸ނ�ǉ��A�C��(ڲ��Ă̾���ݏC���Ή��̈�)
 *                                        �p�����[�^�F�S�������̍ۂ̏o�͓��e��ύX
 *  2008/06/13    1.8   Y.Ishikawa        ���b�g�R�s�[�ɂ��쐬���������̎d�����[���o�͂����
 *                                       �A�P�̖��ׂ̏�񂪂Q���ȏコ��Ȃ��悤�C���B
 *  2008/06/16    1.9   I.Higa           TEMP�̈�G���[����̂��߁Axxpo_categories_v���Q�ȏ�g�p
 *                                       ���Ȃ��悤�ɂ���
 *  2008/06/25    1.10  T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/06/25    1.11  Y.Ishikawa       �����́A����(QUANTITY)�ł͂Ȃ�����ԕi����
 *                                       (RCV_RTN_QUANTITY)���Z�b�g����
 *  2008/07/04    1.12  Y.Majikina       TEMP�̈�G���[����̂��߁Axxcmn_categories4_v���g�p
 *                                       ���Ȃ��悤�ɏC��
 *  2008/07/07    1.13  Y.Majikina       �d�����z�v�Z���́A����ԕi���ʂł͂Ȃ�����(QUANTITY)
 *                                       �ɏC��
 *  2008/07/15    1.14  I.Higa           �u�����Ȃ��d����ԕi�v�ȊO�́A�����w�b�_�̕����R�[�h��
 *                                       ���Ə����VIEW2�Ɣ�t����
 *                                       ����ԕi���уA�h�I���̕����R�[�h�Ƃ͔�t���Ȃ�
 *  2008/07/24    1.15  I.Higa           �u�����Ȃ��d����ԕi�v�̏ꍇ�A�ȉ��̍��ڂ͎���ԕi����
 *                                       ���擾����
 *                                        �u�H��v�A�u�[����v�A�u�E�v�v�A�u�t�уR�[�h�v
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(20) := 'XXPO360004C' ;   -- �p�b�P�[�W��
  gv_print_name      CONSTANT VARCHAR2(20) := '�d�����ו\' ;    -- ���[��
  gv_dept_cd_all     CONSTANT VARCHAR2(5)  := 'ZZZZ';           -- �S������(ALL)
  gn_one             CONSTANT NUMBER  DEFAULT 1;
  gv_language        CONSTANT VARCHAR2(3)  := 'JA';             -- ����
  gv_lot_n_div       CONSTANT VARCHAR2(1) := '0';               -- ���b�g�Ǘ��Ȃ�
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;     -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;      -- �A�v���P�[�V�����iXXPO�j
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�BVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '�]�ƈ�ID' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'MM/DD' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE vendor_code_type IS TABLE OF xxpo_rcv_and_rtn_txns.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE art_code_type    IS TABLE OF xxpo_rcv_and_rtn_txns.item_code%TYPE   INDEX BY BINARY_INTEGER;
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
    deliver_from     DATE,                                              -- �[����FROM
    deliver_to       DATE,                                              -- �[����TO
    item_division    mtl_categories_b.segment1%TYPE,                    -- ���i�敪
    dept_code        po_headers_all.attribute10%TYPE,                   -- �S������
    vendor_code      vendor_code_type,                                  -- �����1�`5
    art_division     mtl_categories_b.segment1%TYPE,                    -- �i�ڋ敪
    art_code         art_code_type,                                     -- �i��1
    crowd1           xxpo_categories_v.category_code%TYPE,              -- �Q1
    crowd2           xxpo_categories_v.category_code%TYPE,              -- �Q2
    crowd3           xxpo_categories_v.category_code%TYPE,              -- �Q3
    security_flg     xxpo_security_supply_v.security_class%TYPE         -- �Z�L�����e�B�敪
  );
--
  TYPE rec_data_type_dtl  IS RECORD (
   category_cd    mtl_categories_b.segment1%TYPE,                         -- ���i�敪�R�[�h
   category_desc  mtl_categories_b.description%TYPE,                      -- ���i�敪��
   loc_cd         hr_locations_all.location_code%TYPE,                    -- �����R�[�h
   loc_name       hr_locations_all.description%TYPE,                      -- ������
   xv_seg1        po_vendors.segment1%TYPE,                               -- �����R�[�h
   vend_shrt_nm   xxcmn_vendors.vendor_short_name%TYPE,                   -- ����於
   category_cd2   mtl_categories_b.segment1%TYPE,                         -- �i�ڋ敪�R�[�h
   category_desc2 mtl_categories_b.description%TYPE,                      -- �i�ڋ敪��
   old_crw_cd     ic_item_mst_b.attribute1%TYPE,                          -- �Q
   item_no        ic_item_mst_b.item_no%TYPE,                             -- �i��(�i�ڃR�[�h
   item_sht_nm    xxcmn_item_mst_b.item_short_name%TYPE,                  -- �i��(�i�ږ�)
   po_attr3       po_lines_all.attribute3%TYPE,                           -- �t��
   txns_date      xxpo_rcv_and_rtn_txns.txns_date%TYPE,                   -- �[����
   lot_no         ic_lots_mst.lot_no%TYPE,                                -- ���b�gNO
   ic_attr1       ic_lots_mst.attribute1%TYPE,                            -- ������
   ic_attr2       ic_lots_mst.attribute2%TYPE,                            -- �ŗL�L��
   ic_attr3       ic_lots_mst.attribute3%TYPE,                            -- �ܖ�����
   order_no       xxpo_rcv_and_rtn_txns.source_document_number%TYPE,      -- ����No
   factry_code    po_vendor_sites_all.vendor_site_code%TYPE,              -- �H��(�H��R�[�h)
   in_cnt         xxpo_rcv_and_rtn_txns.unit_price%TYPE,                  -- ����
   total_cnt      xxpo_rcv_and_rtn_txns.quantity%TYPE,                    -- ����
   rtn_uom        xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE,                 -- �P��
   unit_price     xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE,  -- �P��
   amount_pay     NUMBER,                                                 -- �d�����z
   deliver_dist   mtl_categories_b.segment1%TYPE,                         -- �[����(�[����R�[�h)
   po_attr15      po_lines_all.attribute15%TYPE,                          -- �E�v
   order_loc_cd   hr_locations_all.location_code%TYPE,
   display_1      VARCHAR2(440)
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;           -- �c�ƒP��
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;    -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;         -- �S����
  gv_user_vendor            xxpo_per_all_people_f_v.attribute4%TYPE;         -- �d����R�[�h
  gv_user_vendor_site       xxpo_per_all_people_f_v.attribute6%TYPE;         -- �d����T�C�g�R�[�h
--
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  gn_user_vendor_id         po_vendors.vendor_id%TYPE;
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(15) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(vendor_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_code IN vendor_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vendor_code_loop>>
    FOR ln_cnt IN 1..itbl_vendor_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_vendor_code(ln_cnt) || ''',';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(art_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement (
      itbl_art_code IN art_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<art_code_type_loop>>
    FOR ln_cnt IN 1..itbl_art_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_art_code(ln_cnt) || ''',';
    END LOOP art_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
    iv_name              IN        VARCHAR2,   --   �^�O�l�[��
    iv_value             IN        VARCHAR2,   --   �^�O�f�[�^
    ic_type              IN        CHAR       --   �^�O�^�C�v
  ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(E-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
      ir_param      IN     rec_param_data,    -- 01.���̓p�����[�^�Q
      ov_errbuf     OUT    VARCHAR2,          --    �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    OUT    VARCHAR2,          --    ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     OUT    VARCHAR2           --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_err_code           VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_err_code := 'APP-XXPO-00005' ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- �d����R�[�h�E�d����T�C�g�R�[�h�擾
    -- ====================================================
    BEGIN
      SELECT  xssv.vendor_code
             ,xssv.vendor_site_code
             ,vnd.vendor_id
        INTO  gv_user_vendor
             ,gv_user_vendor_site
             ,gn_user_vendor_id
        FROM  xxpo_security_supply_v xssv
             ,xxcmn_vendors2_v       vnd
       WHERE  xssv.vendor_code    = vnd.segment1 (+)
         AND  xssv.user_id        = gn_user_id
         AND  xssv.security_class = ir_param.security_flg
         AND  ir_param.deliver_from BETWEEN vnd.start_date_active(+)
         AND  vnd.end_date_active(+) ;
--
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key ) ;
        lv_retcode  := gv_status_error ;
        RAISE get_value_expt ;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(E-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
    ir_param      IN  rec_param_data,
    ot_data_rec   OUT NOCOPY tab_data_type_dtl,  -- 02.�擾���R�[�h�Q
    ov_errbuf     OUT VARCHAR2,                  --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                  --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                   --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_sts_num_1       CONSTANT VARCHAR2(1)  := '1';
    cn_sts_num_zero    CONSTANT NUMBER(1)    :=  0;
    cn_sts_num         CONSTANT NUMBER(2)    := -1;
    cv_sts_num_2       CONSTANT VARCHAR2(1)  := '2';
    cv_sts_num_3       CONSTANT VARCHAR2(1)  := '3';
    cv_sts_num_5       CONSTANT VARCHAR2(1)  := '5';
    cv_sts_var_n       CONSTANT VARCHAR2(1)  := 'N';
    cv_sts_var_y       CONSTANT VARCHAR2(1)  := 'Y';
    cv_sts_athrtn_sts  CONSTANT VARCHAR2(8)  := 'APPROVED';
    cv_money_fix       CONSTANT VARCHAR2(2)  := '35';
    cv_cancel          CONSTANT VARCHAR2(2)  := '99';
    cv_comm_division   CONSTANT VARCHAR2(20) := '���i�敪';
    cv_item_division   CONSTANT VARCHAR2(20) := '�i�ڋ敪';
    cv_crowd_cd        CONSTANT VARCHAR2(20) := '�Q�R�[�h';
    cv_per             CONSTANT VARCHAR2(1)  := '%';
--
    -- *** ���[�J���E�ϐ� ***
    lv_comm_where VARCHAR2(32000) DEFAULT NULL;
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order      VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_in         VARCHAR2(1000)  ;
    lv_select_1   VARCHAR2(32000);
    lv_from_1     VARCHAR2(32000);
    lv_where_1    VARCHAR2(32000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================================
    -- ����WHERE
    -- ==================================================================
    -- --------------------------------------
    -- �p�����[�^�F����悪���͍�
    -- --------------------------------------
    IF ( ir_param.vendor_code.COUNT = gn_one ) THEN
      -- 1���̂�
      lv_comm_where := lv_comm_where
               || ' AND rcrt.vendor_id  = ''' || ir_param.vendor_code( gn_one ) || '''';
    ELSIF ( ir_param.vendor_code.COUNT > gn_one ) THEN
      -- 1���ȏ�
      lv_in    := fnc_get_in_statement(ir_param.vendor_code);
      lv_comm_where := lv_comm_where
               || ' AND rcrt.vendor_id IN (' || lv_in || ' ) ';
    ELSE
      NULL;
    END IF;
--
    -- --------------------------------------
    -- �p�����[�^�F�i�ڂ����͍�
    -- --------------------------------------
    IF (ir_param.art_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_comm_where := lv_comm_where
               || ' AND rcrt.item_code  = ''' || ir_param.art_code( gn_one ) || '''';
    ELSIF (ir_param.art_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in    := fnc_get_in_statement( ir_param.art_code );
      lv_comm_where := lv_comm_where
               || ' AND rcrt.item_code IN ( ' || lv_in || ' ) ';
    ELSE
      NULL;
    END IF;
--
    -- ============================================================================================
    -- < �i�ڃJ�e�S��(���i�敪) > --
    -- ============================================================================================
    -- --------------------------------
    -- �p�����[�^�F���i�敪�����͍�
    -- ---------------------------------
    IF ( ir_param.item_division IS NOT NULL) THEN
      lv_comm_where := lv_comm_where
               || ' AND ctgg.category_code = ''' || ir_param.item_division || '''';
    END IF;
--
    -- ============================================================================================
    -- < �i�ڃJ�e�S��(�i�ڋ敪) > --
    -- ============================================================================================
    -- ---------------------------------------
    -- �p�����[�^�F�i�ڋ敪�����͍�
    -- ---------------------------------------
    IF ( ir_param.art_division IS NOT NULL) THEN
      lv_comm_where := lv_comm_where
               || ' AND ctgi.category_code = ''' || ir_param.art_division || '''';
    END IF;
--
    -- ============================================================================================
    -- < �i�ڃJ�e�S��(�Q) > --
    -- ===========================================================================================
--
    -- ���͏��
    -- ���ׂē��͍ς�
    IF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || '''))';
    -- �Q1�̂ݓ��͍ς�
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )';
    -- �Q2�̂ݓ��͍ς�
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )';
    -- �Q3�̂ݓ��͍ς�
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' )';
    -- �Q1�ƌQ2�����͍�
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' ))';
    -- �Q1�ƌQ3�����͍ς�
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' ))';
    -- �Q2�ƌQ3�����͍ς�
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' ))';
    END IF;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    lv_select := ' SELECT '
              || ' ctgg.category_code         AS  category_cd, '        -- ���i�敪�R�[�h
              || ' ctgg.category_description  AS  category_desc, ';     -- ���i�敪��
--
    -- ------------------------------------------
    -- �p�����[�^�F�S��������ZZZZ�������ꍇ
    -- ------------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_select := lv_select
                || ' NULL AS loc_cd, ';
    ELSE
      lv_select := lv_select
                || ' CASE WHEN ( rcrt.txns_type = ''' || cv_sts_num_3 || ''' ) '
                || ' THEN rcrt.department_code '
                || ' ELSE xlv.location_code '
                || ' END AS loc_cd, ';                     -- �����R�[�h
    END IF;
--
    -- -----------------------------------------
    -- �p�����[�^�F�S��������ZZZZ�������ꍇ
    -- -----------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_select := lv_select
                || ' NULL AS loc_name, ';
    ELSE
      lv_select := lv_select
                || ' CASE WHEN ( rcrt.txns_type = ''' || cv_sts_num_3 || ''' ) '
                || ' THEN xlv.location_name '
                || ' ELSE xlv.description '
                || ' END AS  loc_name, ';                            -- ������
    END IF;
--
    lv_select := lv_select
              || ' xvv.segment1               AS  xv_seg1, '         -- �����R�[�h
              || ' xvv.vendor_short_name      AS  vend_shrt_nm, '    -- ����於
              || ' ctgi.category_code         AS  category_cd2, '    -- �i�ڋ敪�R�[�h
              || ' ctgi.category_description  AS  category_desc2,'   -- �i�ڋ敪��
              || ' ximv.old_crowd_code        AS  old_crw_cd, '      -- �Q
              || ' ximv.item_no               AS  item_no, '         -- �i��(�i�ڃR�[�h
              || ' ximv.item_short_name       AS  item_sht_nm, '     -- �i��(�i�ږ�)
              || ' pla.attribute3             AS  po_attr3, '        -- �t��
              || ' rcrt.txns_date             AS  txns_date, '       -- �[����
              || ' DECODE(ximv.lot_ctl,'      || gv_lot_n_div
              || '  ,NULL,ilm.lot_no)        AS lot_no, '            -- ���b�gNO
              || ' ilm.attribute1             AS  ic_attr1, '        -- ������
              || ' ilm.attribute2             AS  ic_attr2, '        -- �ŗL�L��
              || ' ilm.attribute3             AS  ic_attr3, '        -- �ܖ�����
              || ' CASE WHEN '
              || ' ( rcrt.txns_type = ''' || cv_sts_num_1 || ''' ) '
              || ' THEN rcrt.source_document_number '                -- �������ԍ�
              || ' WHEN rcrt.txns_type = ''' || cv_sts_num_2 || ''''
              || ' THEN rcrt.rcv_rtn_number '                        -- ����ԕi�ԍ�
              || ' ELSE NULL '
              || ' END AS order_no, '                                -- ����No
              || ' xvsv.vendor_site_code      AS factry_code,'
              || ' TO_NUMBER(pla.attribute4)  AS in_cnt,'            -- �݌ɓ���
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' (rcrt.rcv_rtn_quantity * '  || cn_sts_num   || ' ),'
              || ' rcrt.rcv_rtn_quantity )    AS   total_cnt,'                  -- ����
              || ' rcrt.rcv_rtn_uom           AS   rtn_uom, '                   -- �P��
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) AS   unit_price, '                -- �P��
              || ' ROUND(DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , ( rcrt.quantity * ' || cn_sts_num || ' ) '
              || ' , rcrt.quantity ) * '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) , '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , ( rcrt.quantity * ' || cn_sts_num || ' ) '
              || ' , rcrt.quantity ) * '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) ), ' || cn_sts_num_zero
              || ' ) AS amount_pay, '                                   -- �d�����z
              || ' xilv.segment1 AS deliver_dist,'                      -- �ۊǑq�ɃR�[�h
              || ' pla.attribute15   AS   po_attr15, '                  -- �E�v
              || ' xlv.location_code AS   order_loc_cd,';
--
    -- ------------------------------------
    -- �p�����[�^�F�i�ڋ敪���T�̏ꍇ
    -- ------------------------------------
    IF ( ir_param.art_division = cv_sts_num_5 ) THEN
      lv_select := lv_select
                || ' ilm.attribute1 || ilm.attribute2 AS display_1 ';
    ELSE
      lv_select := lv_select
                || ' ilm.lot_no AS display_1 ';
    END IF;
--
    -- ===========================================================
    -- FROM�吶��
    -- ===========================================================
    lv_from := ' FROM '
            || ' xxpo_rcv_and_rtn_txns     rcrt, '   -- ����ԕi���сi�A�h�I���j
            || ' po_lines_all              pla, '    -- ��������
            || ' po_headers_all            pha, '    -- �����w�b�_
            || ' xxpo_headers_all          xha, '    -- �����w�b�_�i�A�h�I���j
            || ' po_line_locations_all     plla, '   -- �����[������
            || ' xxcmn_item_mst2_v         ximv, '   -- OPM�i�ڏ��VIEW2
            || ' xxcmn_item_locations2_v   xilv, '   -- OPM�ۊǏꏊ���VIEW2
            || ' xxcmn_vendors2_v          xvv, '    -- �d������VIEW2
            || ' xxcmn_vendor_sites2_v     xvsv, '   -- �d����T�C�g���VIEW2
            || ' ic_lots_mst               ilm, '    -- OPM���b�g�}�X�^
            || ' xxcmn_locations2_v        xlv, '    -- ���Ə����VIEW2
            -- XXPO�J�e�S�����VIEW�i���i�j
            || ' ( SELECT  gic.item_id      AS item_id '
            || '          ,mcb.segment1     AS category_code '
            || '          ,mct.description  AS category_description'
            || '     FROM  gmi_item_categories   gic, '
            || '           mtl_category_sets_tl  mcst, '
            || '           mtl_category_sets_b   mcsb, '
            || '           mtl_categories_b      mcb, '
            || '           mtl_categories_tl     mct '
            || '    WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '      AND  mcst.language          = ''' || gv_language || ''''
            || '      AND  mcsb.structure_id      = mcb.structure_id '
            || '      AND  mcb.category_id        = mct.category_id '
            || '      AND  gic.category_id        = mcb.category_id'
            || '      AND  gic.category_set_id    = mcsb.category_set_id'
            || '      AND  mct.language           = ''' || gv_language || ''''
            || '      AND  mcst.category_set_name = ''' || cv_comm_division || '''' || ') ctgg '
            -- XXPO�J�e�S�����VIEW�i�i�ځj
            || ' ,( SELECT  gic.item_id      AS item_id '
            || '           ,mcb.segment1     AS category_code '
            || '           ,mct.description  AS category_description'
            || '      FROM  gmi_item_categories   gic, '
            || '            mtl_category_sets_tl  mcst, '
            || '            mtl_category_sets_b   mcsb, '
            || '            mtl_categories_b      mcb, '
            || '            mtl_categories_tl     mct '
            || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '       AND  mcst.language          = ''' || gv_language || ''''
            || '       AND  mcsb.structure_id      = mcb.structure_id '
            || '       AND  mcb.category_id        = mct.category_id '
            || '       AND  gic.category_id        = mcb.category_id'
            || '       AND  gic.category_set_id    = mcsb.category_set_id'
            || '       AND  mct.language           = ''' || gv_language || ''''
            || '       AND  mcst.category_set_name = ''' || cv_item_division || '''' || ') ctgi '
            -- XXPO�J�e�S�����VIEW�i�Q�R�[�h�j
            || ' ,( SELECT  gic.item_id   AS item_id '
            || '           ,mcb.segment1  AS category_code '
            || '      FROM  gmi_item_categories   gic, '
            || '            mtl_category_sets_tl  mcst, '
            || '            mtl_category_sets_b   mcsb, '
            || '            mtl_categories_b      mcb, '
            || '            mtl_categories_tl     mct '
            || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '       AND  mcst.language          = ''' || gv_language || ''''
            || '       AND  mcsb.structure_id      = mcb.structure_id '
            || '       AND  mcb.category_id        = mct.category_id '
            || '       AND  gic.category_id        = mcb.category_id'
            || '       AND  gic.category_set_id    = mcsb.category_set_id'
            || '       AND  mct.language           = ''' || gv_language || ''''
            || '       AND  mcst.category_set_name = ''' || cv_crowd_cd || '''' || ') ctgc ';
--
    -- ===========================================================
    -- WHERE�吶��
    -- ===========================================================
    lv_where := ' WHERE '
             || '     pha.org_id      =  ' || gn_sales_class
             || ' AND pha.segment1    = rcrt.source_document_number '   -- �������ԍ�
             || ' AND pha.segment1    = xha.po_header_number '          -- �����ԍ�
             || ' AND pha.authorization_status  = ''' || cv_sts_athrtn_sts || ''''
             || ' AND pha.attribute1 >= ''' || cv_money_fix || ''''     -- �����X�e�[�^�X(DFF)
             || ' AND pha.attribute1 <  ''' || cv_cancel    || ''''
             || ' AND rcrt.txns_date BETWEEN ''' || ir_param.deliver_from || ''' AND '''
             || ir_param.deliver_to || '''';
--
    -- ---------------------------------------
    -- �p�����[�^�F�S�����������͍�
    -- ---------------------------------------
    IF ( ir_param.dept_code <> gv_dept_cd_all ) THEN
      IF ( ir_param.dept_code IS NOT NULL ) THEN
        lv_where := lv_where
                 || ' AND ((pha.attribute10 = '''       || ir_param.dept_code || ''')'
                 || '  OR  ( rcrt.department_code = ''' || ir_param.dept_code || '''))';
      END IF;
    END IF;
--
    -- ============================================================================================
    -- < �������ׁ������[������ > --
    -- ============================================================================================
    lv_where := lv_where
             || ' AND pha.po_header_id  =   pla.po_header_id '                -- �����w�b�_ID
             || ' AND pla.line_num      =   rcrt.source_document_line_num '   -- ���הԍ�
             || ' AND pla.po_line_id    =   plla.po_line_id '                 -- ��������ID
             || ' AND pla.cancel_flag   = '''    || cv_sts_var_n || ''''      -- ����t���O
             || ' AND pla.attribute14   = '''    || cv_sts_var_y || ''''      -- ���z�m��t���O
             || ' AND (( rcrt.txns_type = '''    || cv_sts_num_1 || ''' ) '
             || '  OR  ( rcrt.txns_type = ''' || cv_sts_num_2 || ''' )'
             || ' AND ( rcrt.quantity > ' || cn_sts_num_zero || ' )) '        -- ����
    -- ============================================================================================
    -- �K�p���Ǘ��Ώۃ}�X�^�̍i����
    -- ============================================================================================
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN ximv.start_date_active AND ximv.end_date_active'
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xvv.start_date_active AND xvv.end_date_active'
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xvsv.start_date_active AND xvsv.end_date_active '
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xlv.start_date_active AND xlv.end_date_active '
             || ' AND xilv.date_from <= ''' || ir_param.deliver_from || ''''
             || ' AND (( xilv.date_to >= ''' || ir_param.deliver_from || ''' )'
             || '  OR ( xilv.date_to IS NULL )) '
    -- ============================================================================================
    -- < ���b�g���i�� > --
    -- ============================================================================================
             || ' AND rcrt.item_id      =  ilm.item_id(+) '                  -- �i��ID
             || ' AND rcrt.lot_id       =  ilm.lot_id(+) '                   -- ���b�gID
             || ' AND rcrt.item_id      =  ximv.item_id '                    -- �i��ID
    -- ============================================================================================
    -- < ���� > --
    -- ============================================================================================
             || ' AND pha.attribute10       =   xlv.location_code '      -- �����R�[�h:attr10
    -- ============================================================================================
    -- < ����� > --
    -- ============================================================================================
             || ' AND rcrt.vendor_id    =   xvv.vendor_id '
    -- ============================================================================================
    -- < ���ɑq��> --
    -- ============================================================================================
             || ' AND pha.attribute5    =   xilv.segment1(+) '         -- �[����R�[�h:attr5
    -- ============================================================================================
    -- < �H�� > --
    -- ============================================================================================
             || ' AND pha.vendor_id          = xvv.vendor_id '
             || ' AND xvsv.vendor_site_code  = pla.attribute2 '       -- �H��R�[�h(DFF)
             || ' AND ctgg.item_id           = ximv.item_id'
             || ' AND ctgi.item_id           = ximv.item_id'
             || ' AND ctgc.item_id           = ximv.item_id'
             || ' AND rcrt.item_id           = ctgg.item_id'
             || ' AND rcrt.item_id           = ctgi.item_id'
             || ' AND rcrt.item_id           = ctgc.item_id';
--
    -- ============================================================================================
    -- < �Z�L�����e�B > --
    -- ============================================================================================
    IF ( ir_param.security_flg = cv_sts_num_2 ) THEN
      lv_where := lv_where
               || ' AND (( pha.attribute3 = ''' || gn_user_vendor_id || ''' )';
      IF ( gn_user_vendor_id IS NULL ) THEN
        -- �d����ID�Ȃ�
        lv_where := lv_where
                 || ' OR ((pha.vendor_id IS NULL) ';
      ELSIF ( gn_user_vendor_id IS NOT NULL ) THEN
        lv_where := lv_where
                 || '  OR  ((pha.vendor_id  = ''' || gn_user_vendor_id || ''' )'; -- ����
      END IF;
      IF ( gv_user_vendor_site IS NOT NULL) THEN
        lv_where := lv_where
                 || '  AND  NOT EXISTS(SELECT po_line_id '
                 ||                  ' FROM   po_lines_all pl_sub '
                 ||                  ' WHERE  pl_sub.po_header_id = pha.po_header_id '
                 ||                  ' AND  NVL(pl_sub.attribute2,''*'') '
                 ||                  ' <> '''|| gv_user_vendor_site ||''''
                 ||                  ' ))) ';
      ELSE
        lv_where := lv_where
                   || ' )) ';
      END IF;
    END IF;
--
    -- =======================================================================================
    -- �����Ȃ��d���ԕi�擾SQL
    -- =======================================================================================
    lv_select_1 := ' SELECT '
                || ' ctgg.category_code          AS  category_cd,'
                || ' ctgg.category_description   AS  category_desc,';
--
      IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
        lv_select_1 := lv_select_1
                || ' NULL                       AS  loc_cd, '
                || ' NULL                       AS  loc_name,';
      ELSE
        lv_select_1 := lv_select_1
                || ' rcrt.department_code       AS  loc_cd,'
                || ' xlv.location_name          AS  loc_name,';
      END IF;
--
    lv_select_1 := lv_select_1
                || ' xvv.segment1               AS  xv_seg1,'
                || ' xvv.vendor_short_name      AS  vend_shrt_nm,'
                || ' ctgi.category_code         AS  category_cd2,'
                || ' ctgi.category_description  AS  category_desc2,'
                || ' ximv.old_crowd_code        AS  old_crw_cd,'
                || ' ximv.item_no               AS  item_no,'
                || ' ximv.item_short_name       AS  item_sht_nm,'
                || ' rcrt.futai_code            AS  po_attr3,'
                || ' rcrt.txns_date             AS  txns_date,'
                || ' DECODE(ximv.lot_ctl,'      || gv_lot_n_div
                || '  ,NULL,ilm.lot_no)        AS lot_no, '
                || ' ilm.attribute1             AS  ic_attr1,'
                || ' ilm.attribute2             AS  ic_attr2,'
                || ' ilm.attribute3             AS  ic_attr3,'
                || ' rcrt.rcv_rtn_number        AS  order_no,'
                || ' rcrt.factory_code          AS  factry_code,'
                || ' rcrt.conversion_factor     AS  in_cnt,'
                || ' rcrt.rcv_rtn_quantity * ' || cn_sts_num || ' AS total_cnt,'
                || ' rcrt.rcv_rtn_uom           AS  rtn_uom,'
                || ' rcrt.kobki_converted_unit_price  AS  unit_price,'
                || ' ROUND((( rcrt.quantity * ' || cn_sts_num || ' ) * ( '
                || ' rcrt.kobki_converted_unit_price )),' || cn_sts_num_zero || ' )'
                || ' AS amount_pay,'
                || ' rcrt.location_code         AS  deliver_dist,'
                || ' rcrt.line_description      AS  po_attr15,'
                || ' xlv.location_code          AS  order_loc_cd,';
--
    -- ------------------------------------
    -- �p�����[�^�F�i�ڋ敪���T�̏ꍇ
    -- ------------------------------------
    IF ( ir_param.art_division = cv_sts_num_5 ) THEN
      lv_select_1 := lv_select_1
                  || ' ilm.attribute1 || ilm.attribute2 AS display_1 ';
    ELSE
      lv_select_1 := lv_select_1
                  || ' ilm.lot_no AS display_1 ';
    END IF;
--
    -- ===========================================================
    -- FROM�吶��
    -- ===========================================================
    lv_from_1 := ' FROM '
              || ' xxpo_rcv_and_rtn_txns     rcrt,'
              || ' xxcmn_item_mst2_v         ximv,'
              || ' xxcmn_vendors2_v          xvv,'
              || ' ic_lots_mst               ilm,'
              || ' xxcmn_locations2_v        xlv,'
              -- XXPO�J�e�S�����VIEW�i���i�j
              || ' ( SELECT  gic.item_id      AS item_id '
              || '          ,mcb.segment1     AS category_code '
              || '          ,mct.description  AS category_description'
              || '     FROM  gmi_item_categories   gic, '
              || '           mtl_category_sets_tl  mcst, '
              || '           mtl_category_sets_b   mcsb, '
              || '           mtl_categories_b      mcb, '
              || '           mtl_categories_tl     mct '
              || '    WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '      AND  mcst.language          = ''' || gv_language || ''''
              || '      AND  mcsb.structure_id      = mcb.structure_id '
              || '      AND  mcb.category_id        = mct.category_id '
              || '      AND  gic.category_id        = mcb.category_id'
              || '      AND  gic.category_set_id    = mcsb.category_set_id'
              || '      AND  mct.language           = ''' || gv_language || ''''
              || '      AND  mcst.category_set_name = ''' || cv_comm_division || '''' || ') ctgg '
               -- XXPO�J�e�S�����VIEW�i�i�ځj
              || ' ,( SELECT  gic.item_id      AS item_id '
              || '           ,mcb.segment1     AS category_code '
              || '           ,mct.description  AS category_description'
              || '      FROM  gmi_item_categories   gic, '
              || '            mtl_category_sets_tl  mcst, '
              || '            mtl_category_sets_b   mcsb, '
              || '            mtl_categories_b      mcb, '
              || '            mtl_categories_tl     mct '
              || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '       AND  mcst.language          = ''' || gv_language || ''''
              || '       AND  mcsb.structure_id      = mcb.structure_id '
              || '       AND  mcb.category_id        = mct.category_id '
              || '       AND  gic.category_id        = mcb.category_id'
              || '       AND  gic.category_set_id    = mcsb.category_set_id'
              || '       AND  mct.language           = ''' || gv_language || ''''
              || '       AND  mcst.category_set_name = ''' || cv_item_division || '''' || ') ctgi '
              -- XXPO�J�e�S�����VIEW�i�Q�R�[�h�j
              || ' ,( SELECT  gic.item_id   AS item_id '
              || '           ,mcb.segment1  AS category_code '
              || '      FROM  gmi_item_categories   gic, '
              || '            mtl_category_sets_tl  mcst, '
              || '            mtl_category_sets_b   mcsb, '
              || '            mtl_categories_b      mcb, '
              || '            mtl_categories_tl     mct '
              || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '       AND  mcst.language          = ''' || gv_language || ''''
              || '       AND  mcsb.structure_id      = mcb.structure_id '
              || '       AND  mcb.category_id        = mct.category_id '
              || '       AND  gic.category_id        = mcb.category_id'
              || '       AND  gic.category_set_id    = mcsb.category_set_id'
              || '       AND  mct.language           = ''' || gv_language || ''''
              || '       AND  mcst.category_set_name = ''' || cv_crowd_cd || '''' || ') ctgc ';
--
    -- ===========================================================
    -- WHERE�吶��
    -- ===========================================================
    lv_where_1 := ' WHERE '
               || '     rcrt.source_document_number IS NULL'
               || ' AND rcrt.txns_date BETWEEN ''' || ir_param.deliver_from || ''' AND '''
               || ir_param.deliver_to || ''''
               || ' AND rcrt.source_document_line_num IS NULL'
               || ' AND  rcrt.quantity > ' || cn_sts_num_zero
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN ximv.start_date_active AND ximv.end_date_active'
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN xvv.start_date_active AND xvv.end_date_active'
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN xlv.start_date_active AND xlv.end_date_active '
               || ' AND rcrt.item_id           = ilm.item_id(+)'
               || ' AND rcrt.lot_id            = ilm.lot_id(+)'
               || ' AND rcrt.item_id           = ximv.item_id'
               || ' AND rcrt.department_code   = xlv.location_code'
               || ' AND rcrt.vendor_id         = xvv.vendor_id'
               || ' AND ctgg.item_id           = ximv.item_id'
               || ' AND ctgi.item_id           = ximv.item_id'
               || ' AND ctgc.item_id           = ximv.item_id'
               || ' AND rcrt.item_id           = ctgg.item_id'
               || ' AND rcrt.item_id           = ctgi.item_id'
               || ' AND rcrt.item_id           = ctgc.item_id';
--
    -- ---------------------------------------
    -- �p�����[�^�F�S�����������͍�
    -- ---------------------------------------
    IF ( ir_param.dept_code <> gv_dept_cd_all ) THEN
      IF ( ir_param.dept_code IS NOT NULL ) THEN
        lv_where_1 := lv_where_1
                 || ' AND  ( rcrt.department_code = ''' || ir_param.dept_code || ''')';
      END IF;
    END IF;
--
    -- ============================================================================================
    -- < �Z�L�����e�B > --
    -- ============================================================================================
    IF ( ir_param.security_flg = cv_sts_num_2 ) THEN
      lv_where_1 := lv_where_1
               || ' AND (( rcrt.assen_vendor_id = ''' || gn_user_vendor_id || ''' )';
      IF ( gn_user_vendor_id IS NULL ) THEN
        -- �d����ID�Ȃ�
        lv_where_1 := lv_where_1
                 || ' OR ((rcrt.vendor_id IS NULL) ';
      ELSIF ( gn_user_vendor_id IS NOT NULL ) THEN
        lv_where_1 := lv_where_1
                 || '  OR  ((rcrt.vendor_id  = ''' || gn_user_vendor_id || ''' )'; -- ����
      END IF;
      IF ( gv_user_vendor_site IS NOT NULL) THEN
        lv_where_1 := lv_where_1
                   || '  AND  NOT EXISTS(SELECT xrart_sub.factory_code '
                   ||                  ' FROM   xxpo_rcv_and_rtn_txns xrart_sub '
                   ||                  ' WHERE  xrart_sub.rcv_rtn_number = rcrt.rcv_rtn_number '
                   ||                  ' AND  NVL(xrart_sub.factory_code,''*'') '
                   ||                  ' <> '''|| gv_user_vendor_site ||''''
                   ||                  ' ))) ';
      ELSE
        lv_where_1 := lv_where_1
                 || ' )) ';
      END IF;
    END IF;
--
    -- ===========================================================
    -- ORDER BY�吶��
    -- ===========================================================
    lv_order := ' ORDER BY '
             || ' category_cd   ASC, ';        -- ���i�敪
--
    -- ----------------------------------------
    -- �p�����[�^�F�S��������ZZZZ�̏ꍇ
    -- ----------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_order := lv_order
               || ' xv_seg1       ASC, '       -- �����
               || ' category_cd2  ASC, '       -- �i�ڋ敪
               || ' old_crw_cd    ASC, '       -- �Q
               || ' item_no       ASC, '       -- �i�ڃR�[�h
               || ' po_attr3      ASC, '       -- �t��
               || ' txns_date     ASC, '       -- �[����
               || ' display_1     ASC, '       -- �\����1
               || ' order_no      ASC  ';
--
    -- -----------------------------------------
    -- �p�����[�^�F�S��������ZZZZ�ȊO�̏ꍇ
    -- -----------------------------------------
    ELSE
      lv_order := lv_order
               || ' order_loc_cd  ASC, '       -- ����
               || ' xv_seg1       ASC, '       -- �����
               || ' category_cd2  ASC, '       -- �i�ڋ敪
               || ' old_crw_cd    ASC, '       -- �Q
               || ' item_no       ASC, '       -- �i�ڃR�[�h
               || ' po_attr3      ASC, '       -- �t��
               || ' txns_date     ASC, '       -- �[����
               || ' display_1     ASC, '       -- �\����1
               || ' order_no      ASC  ';
    END IF;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_select || lv_from
           || lv_where  || lv_comm_where
           || ' UNION ALL '
           || lv_select_1 || lv_from_1
           || lv_where_1  || lv_comm_where
           || lv_order ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
--
--
--
  /***********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(E-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
    ir_param          IN  rec_param_data,    -- 01.���R�[�h  �F�p�����[�^
    ov_errbuf         OUT VARCHAR2,          --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,          --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2           --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           CONSTANT VARCHAR2(100) := '*' ;   -- �����l
    lc_break_null           CONSTANT VARCHAR2(100) := '**' ;  -- �m�t�k�k����
    lc_flg_y                CONSTANT VARCHAR2(100) := 'Y';
    lc_flg_n                CONSTANT VARCHAR2(100) := 'N';
    lc_num_zero             CONSTANT NUMBER DEFAULT 0;
    lc_num_one              CONSTANT NUMBER DEFAULT 1;
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_good_class           VARCHAR2(100) DEFAULT lc_break_init;   -- ���i�敪
    lv_location             VARCHAR2(100) DEFAULT lc_break_init;   -- ����
    lv_vendor_name          VARCHAR2(100) DEFAULT lc_break_init;   -- �����
    lv_item_class           VARCHAR2(100) DEFAULT lc_break_init;   -- �i�ڋ敪
    lv_crw_cd               VARCHAR2(100) DEFAULT lc_break_init;   -- �Q�R�[�h
    lv_futai                VARCHAR2(100) DEFAULT lc_break_init;   -- �t�уR�[�h
    lv_item_no              VARCHAR2(100) DEFAULT lc_break_init;   -- �i�ڃR�[�h
    lv_txns_date            VARCHAR2(100) DEFAULT lc_break_init;   -- �[����
    lv_flg                  VARCHAR2(1)   DEFAULT lc_break_init;
    ln_total                NUMBER        DEFAULT 0;
    ln_amount               NUMBER        DEFAULT 0;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
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
    -- ���ڃf�[�^���o����
    --=====================================================
    prc_get_report_data(
      ir_param      => ir_param,
      ot_data_rec   => gt_main_data,   --    02.�擾���R�[�h�Q
      ov_errbuf     => lv_errbuf,      --    �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,     --    ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg       --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
--
    -- -----------------------------------------------------
    -- ���[�U�[�J�n�^�O�o��
    -- -----------------------------------------------------
--
-- =====================================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
-- =====================================================================
--
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- ���{��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'output_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
--
    -- �S������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charge_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gv_user_dept, 1, 10);
--
    -- �S���Җ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'agent' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gv_user_name, 1, 14);
--
    -- �N����FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                         SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),1,4);
--
    -- �N����FROM(��)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),6,2);
--
    -- �N����FROM(��)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),9,2);
--
    -- �N����TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),1,4);
--
    -- �N����TO(��)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),6,2);
--
    -- �N����TO(��)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),9,2);
--
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ���|�[�g�^�C�g��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_print_name;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- ���i�敪�u���C�N
      -- =====================================================
      -- ���i�敪���؂�ւ�����ꍇ
      IF ( NVL(gt_main_data(i).category_cd, lc_break_null ) <> lv_good_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_good_class <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �QG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �QLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- �S�������v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- ���i�敪�v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- �i�ڋ敪G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- ����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- ���i�敪G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- ���i�敪LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���i�敪G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- ���i�敪�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���i�敪�F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_div_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_cd,1,1);
        -- ���i�敪�F����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_desc,1,30);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_good_class  := NVL( gt_main_data(i).category_cd, lc_break_null )  ;
        lv_location := lc_break_init ;
      END IF;
--
      -- =====================================================
      -- �����u���C�N
      -- =====================================================
      -- �������؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).loc_cd, lc_break_null ) <> lv_location ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_location <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �QG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �QLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- �S�������v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- �i�ڋ敪G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- ����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- ����LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_loc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ����G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_loc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
--
        -- �����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).loc_cd,1,4);
--
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).loc_name,1,20);
--
        -- �����t���O(�\�����f�p)
        IF (ir_param.dept_code = gv_dept_cd_all) THEN
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lc_num_zero;
        ELSE
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lc_num_one;
        END IF;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_location  := NVL( gt_main_data(i).loc_cd, lc_break_null )  ;
        lv_vendor_name := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- �����u���C�N
      -- =====================================================
      -- ����悪�؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).xv_seg1, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_vendor_name <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �QG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �QLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����v�t���O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- �i�ڋ敪G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- �����LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vendor' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �����G�f�[�^�^�O�o��
        -- -----------------------------------------------------
--
        -- �����F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).xv_seg1,1,4);
--
        -- �����F����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).vend_shrt_nm,1,20);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_vendor_name  := NVL( gt_main_data(i).xv_seg1, lc_break_null )  ;
        lv_item_class := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- �i�ڋ敪�u���C�N
      -- =====================================================
      -- �i�ڋ敪���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).category_cd2, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �QG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �QLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i�ڋ敪G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- �i�ڋ敪LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
       -- -----------------------------------------------------
        -- �i�ڋ敪G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �i�ڋ敪G�f�[�^�^�O�o��
        -- -----------------------------------------------------
--
        -- �i�ڋ敪�F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_cd2,1,1);
--
        -- �i�ڋ敪�F����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR(gt_main_data(i).category_desc2,1,30);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class  := NVL( gt_main_data(i).category_cd2, lc_break_null )  ;
        lv_crw_cd := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- �Q�R�[�h�u���C�N
      -- =====================================================
      -- �Q�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).old_crw_cd, lc_break_null ) <> lv_crw_cd ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        lv_flg := lc_flg_n;
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_crw_cd <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �QG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �QLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �Q�R�[�hLG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_crow' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- �Q�R�[�hG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_crow' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �Q�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'crow_id' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).old_crw_cd,1,4);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_crw_cd  := NVL( gt_main_data(i).old_crw_cd, lc_break_null )  ;
        lv_item_no := lc_break_init ;
      END IF;
--
      -- =====================================================
      -- �i�ڃR�[�h�u���C�N
      -- =====================================================
      -- �i�ڃR�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).item_no, lc_break_null ) <> lv_item_no ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        lv_flg := lc_flg_n;
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_no <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �i��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- �i��LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_goods' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- �i��G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_goods' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �i��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_no,1,7);
--
        -- �i�ږ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_sht_nm' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_sht_nm,1,20);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_no  := NVL( gt_main_data(i).item_no, lc_break_null )  ;
        lv_futai := lc_break_init ;
      END IF;
--
      -- =====================================================
      --�t�уR�[�h�u���C�N
      -- =====================================================
      -- �t�уR�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).po_attr3, lc_break_null ) <> lv_futai ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_futai <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �t��G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �t��LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �t��LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_futai' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- �t��G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_futai' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �t��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_attr3' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).po_attr3,1,1);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_futai  := NVL( gt_main_data(i).po_attr3, lc_break_null )  ;
        lv_txns_date := lc_break_init ;
      END IF;
--
      -- =====================================================
      --�[�����u���C�N
      -- =====================================================
      -- �[�������؂�ւ�����ꍇ
      IF ( TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format) <> lv_txns_date ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_txns_date <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- ����LG�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- �[����G�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[����LG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- �[����LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- �[����G�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �[����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=
                                         TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format);
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_txns_date  := TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format);
      END IF;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
           -- �t�уR�[�h���؂�ւ�����ꍇ
      IF ( lv_flg <> lc_flg_y ) THEN
        -- -----------------------------------------------------
        -- ����LG�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_line' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
      -- -----------------------------------------------------
      -- ����G�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���b�gNO
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).lot_no,1,10);
--
     -- ������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'create_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=  TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).ic_attr1, gc_char_y_format), gc_char_y_format);
--
      -- �ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'bst_bef_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).ic_attr3, gc_char_y_format), gc_char_y_format);
--
      -- �ŗL�ԍ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pucu_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).ic_attr2,1,6);
--
      -- ����NO
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).order_no,1,12);
--
      -- �H��R�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).factry_code,1,4);
--
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'in_cnt' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).in_cnt;
--
      -- ����
      IF ( gt_main_data(i).total_cnt IS NOT NULL ) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'total_cnt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).total_cnt;
      END IF;
--
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_uom' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).rtn_uom,1,4);
--
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_price;
--
      -- �d�����z
      IF ( gt_main_data(i).amount_pay IS NOT NULL ) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_pay' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).amount_pay;
      END IF;
--
      -- �[����(�[����R�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_dist' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).deliver_dist,1,4);
--
      -- �E�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'recapitulation' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).po_attr15,1,20);
--
      lv_flg := lc_flg_y;
      ln_total := ln_total + gt_main_data(i).total_cnt;
      ln_amount  := ln_amount + gt_main_data(i).amount_pay;
--
      -- -----------------------------------------------------
      -- ����G�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    -- -----------------------------------------------------
    -- ����LG�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- �[����G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �[����LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �t��G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �t��LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �i��G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i��LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �QG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �QLG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �����v�t���O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- �S�������v�t���O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- ���i�敪�v�t���O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- �����v�t���O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
    ------------------------------
    -- �i�ڋ敪G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �����G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- ����G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ����LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ---------------------------
    -- ����
    -- ---------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_cnt' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(ln_total,1,19);
    -- ---------------------------
    -- �d�������v
    -- ---------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(ln_amount,1,20);
--
    ------------------------------
    -- ���i�敪G�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�敪LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- �f�[�^LG�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-00009' ) ;
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
  END prc_create_xml_data ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain (
      iv_deliver_from      IN    VARCHAR2,  -- �[����FROM
      iv_deliver_to        IN    VARCHAR2,  -- �[����TO
      iv_item_division     IN    VARCHAR2,  -- ���i�敪
      iv_dept_code         IN    VARCHAR2,  -- �S������
      iv_vendor_code1      IN    VARCHAR2,  -- �����1
      iv_vendor_code2      IN    VARCHAR2,  -- �����2
      iv_vendor_code3      IN    VARCHAR2,  -- �����3
      iv_vendor_code4      IN    VARCHAR2,  -- �����4
      iv_vendor_code5      IN    VARCHAR2,  -- �����5
      iv_art_division      IN    VARCHAR2,  -- �i�ڋ敪
      iv_crowd1            IN    VARCHAR2,  -- �Q1
      iv_crowd2            IN    VARCHAR2,  -- �Q2
      iv_crowd3            IN    VARCHAR2,  -- �Q3
      iv_art1              IN    VARCHAR2,  -- �i��1
      iv_art2              IN    VARCHAR2,  -- �i��2
      iv_art3              IN    VARCHAR2,  -- �i��3
      iv_security_flg      IN    VARCHAR2,  -- �Z�L�����e�B�敪
      ov_errbuf            OUT   VARCHAR2,  -- �G���[�E���b�Z�[�W            # �Œ� #
      ov_retcode           OUT   VARCHAR2,  -- ���^�[���E�R�[�h              # �Œ� #
      ov_errmsg            OUT   VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
--
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
    lv_xml_string           VARCHAR2(32000) DEFAULT '*';
    cv_num                  CONSTANT VARCHAR2(1)  := '1';
    ln_vendor_code          NUMBER DEFAULT 0; -- �����
    ln_art_code             NUMBER DEFAULT 0; -- �i��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gv_report_id                := 'XXPO360004T';      -- ���[ID
    gd_exec_date                := SYSDATE;            -- ���{��
--
    -- �p�����[�^�i�[
    lr_param_rec.deliver_from   := FND_DATE.STRING_TO_DATE(iv_deliver_from , gc_char_dt_format);
    lr_param_rec.deliver_to     := FND_DATE.STRING_TO_DATE(iv_deliver_to , gc_char_dt_format);
    lr_param_rec.item_division  := iv_item_division;
    lr_param_rec.dept_code      := iv_dept_code;
    lr_param_rec.art_division   := iv_art_division;
    lr_param_rec.crowd1         := iv_crowd1;
    lr_param_rec.crowd2         := iv_crowd2;
    lr_param_rec.crowd3         := iv_crowd3;
    lr_param_rec.security_flg   := iv_security_flg;
--
    -- �����P
    IF TRIM(iv_vendor_code1) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- �����Q
    IF TRIM(iv_vendor_code2) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- �����R
    IF TRIM(iv_vendor_code3) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- �����S
    IF TRIM(iv_vendor_code4) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- �����T
    IF TRIM(iv_vendor_code5) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- �i�ڂP
    IF TRIM(iv_art1) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art1;
    END IF;
    -- �i�ڂQ
    IF TRIM(iv_art2) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art2;
    END IF;
    -- �i�ڂR
    IF TRIM(iv_art3) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art3;
    END IF;
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize (
        ir_param          => lr_param_rec,       -- ���̓p�����[�^�Q
        ov_errbuf         => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode        => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data (
       ir_param         => lr_param_rec,       -- ���̓p�����[�^���R�[�h
       ov_errbuf        => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ov_retcode       => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
       ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <loc_flg>' || cv_num || '</loc_flg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main (
    errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
    retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
    iv_deliver_from       IN    VARCHAR2,  -- �[����FROM
    iv_deliver_to         IN    VARCHAR2,  -- �[����TO
    iv_item_division      IN    VARCHAR2,  -- ���i�敪
    iv_dept_code          IN    VARCHAR2,  -- �S������
    iv_vendor_code1       IN    VARCHAR2,  -- �����1
    iv_vendor_code2       IN    VARCHAR2,  -- �����2
    iv_vendor_code3       IN    VARCHAR2,  -- �����3
    iv_vendor_code4       IN    VARCHAR2,  -- �����4
    iv_vendor_code5       IN    VARCHAR2,  -- �����5
    iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
    iv_crowd1             IN    VARCHAR2,  -- �Q1
    iv_crowd2             IN    VARCHAR2,  -- �Q2
    iv_crowd3             IN    VARCHAR2,  -- �Q3
    iv_art1               IN    VARCHAR2,  -- �i��1
    iv_art2               IN    VARCHAR2,  -- �i��2
    iv_art3               IN    VARCHAR2,  -- �i��3
    iv_security_flg       IN    VARCHAR2   -- �Z�L�����e�B�敪
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain (
     iv_deliver_from     =>  iv_deliver_from,   -- �[����FROM
     iv_deliver_to       =>  iv_deliver_to,     -- �[����TO
     iv_item_division    =>  iv_item_division,  -- ���i�敪
     iv_dept_code        =>  iv_dept_code,      -- �S������
     iv_vendor_code1     =>  iv_vendor_code1,   -- �����1
     iv_vendor_code2     =>  iv_vendor_code2,   -- �����2
     iv_vendor_code3     =>  iv_vendor_code3,   -- �����3
     iv_vendor_code4     =>  iv_vendor_code4,   -- �����4
     iv_vendor_code5     =>  iv_vendor_code5,   -- �����5
     iv_art_division     =>  iv_art_division,   -- �i�ڋ敪
     iv_crowd1           =>  iv_crowd1,         -- �Q1
     iv_crowd2           =>  iv_crowd2,         -- �Q2
     iv_crowd3           =>  iv_crowd3,         -- �Q3
     iv_art1             =>  iv_art1,           -- �i��1
     iv_art2             =>  iv_art2,           -- �i��2
     iv_art3             =>  iv_art3,           -- �i��3
     iv_security_flg     =>  iv_security_flg,   -- �Z�L�����e�B�敪
     ov_errbuf           =>  lv_errbuf,         -- �G���[�E���b�Z�[�W            # �Œ� #
     ov_retcode          =>  lv_retcode,        -- ���^�[���E�R�[�h              # �Œ� #
     ov_errmsg           =>  lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF (( lv_retcode = gv_status_error )
      OR ( lv_retcode = gv_status_warn )) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo360004c ;
/
