CREATE OR REPLACE PACKAGE BODY xxpo780001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo780001c(body)
 * Description      : �����Y�؏����i�L���x�����E�j
 * MD.050/070       : �����Y�؏����i�L���x�����E�jIssue1.0  (T_MD050_BPO_780)
 *                    ���������L���x�����E�m�F���i�ɓ����j  (T_MD070_BPO_78A)
 * Version          : 1.9
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_check_param_info      PROCEDURE : �p�����[�^�`�F�b�N(A-1)
 *  prc_initialize            PROCEDURE : �O����(A-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(A-3)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(A-4)
 *  prc_ins_data              PROCEDURE : TEMP�e�[�u���f�[�^�o�^(A-6)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/03    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/02/06    1.1   Masayuki Ikeda   �E�󒍖��׃A�h�I���ƕi�ڃ}�X�^��R�t����ꍇ�A�h�m�u
 *                                         �i�ڃ}�X�^�𒇉��B
 *                                       �E���b�Z�[�W�R�[�h���C��
 *  2008/03/10    1.2   Masayuki Ikeda   �E�ύX�v��No.81�Ή�
 *  2008/06/20    1.3  Yasuhisa Yamamoto ST�s��Ή�#135
 *  2008/07/29    1.4   Satoshi Yunba    �֑������Ή�
 *  2008/12/05    1.5  Tsuyoki Yoshimoto �{�ԏ�Q#446
 *  2008/12/25    1.6  Takao Ohashi      �{�ԏ�Q#848,850
 *  2009/03/04    1.7  Akiyoshi Shiina   �{�ԏ�Q#1266�Ή�
 *  2019/09/11    1.8  N.Abe             E_�{�ғ�_15601�i���Y_�y���ŗ��Ή��j
 *                                       �R���J�����g����ύX�F�v�Z�� �� ���������L���x�����E�m�F���i�ɓ����j
 *  2019/10/18    1.9  N.Abe             E_�{�ғ�_15601�Ή��i�ǉ��Ή��j
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo780001c' ;   -- �p�b�P�[�W��
-- 2019/09/11 Ver1.8 Add Start
  gn_request_id           CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
-- 2019/09/11 Ver1.8 Add End
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag                CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_lookup_type_shikyu_class   CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_SHIKYU_CLASS' ;
  gc_lookup_type_fix_class      CONSTANT VARCHAR2(100) := 'XXWSH_AMOUNT_FIX_CLASS' ;
  gc_lookup_type_tax_rate       CONSTANT VARCHAR2(100) := 'XXCMN_CONSUMPTION_TAX_RATE' ;
  gc_lookup_meaning_shikyu_irai CONSTANT VARCHAR2(100) := '�x���˗�' ;
  gc_lookup_meaning_kakutei     CONSTANT VARCHAR2(100) := '�m��' ;
-- 2019/10/18 Ver1.9 Add Start
  gc_lkup_acct_pay              CONSTANT VARCHAR2(20)  := 'XXPO_ACCOUNT_PAYABLE'; -- �U����
  gc_lkup_mean_acct_pay         CONSTANT VARCHAR2(20)  := '�U������';
-- 2019/10/18 Ver1.9 Add End
--
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
  gc_ship_rcv_pay_ctg_mhn       CONSTANT VARCHAR2(2)   := '01' ;    -- ���{�o��
  gc_ship_rcv_pay_ctg_hik       CONSTANT VARCHAR2(2)   := '02' ;    -- �p���o��
  gc_ship_rcv_pay_ctg_kra       CONSTANT VARCHAR2(2)   := '03' ;    -- �q�֓���
  gc_ship_rcv_pay_ctg_hen       CONSTANT VARCHAR2(2)   := '04' ;    -- �ԕi����
  gc_ship_rcv_pay_ctg_ysy       CONSTANT VARCHAR2(2)   := '05' ;    -- �L���o��
  gc_ship_rcv_pay_ctg_yhe       CONSTANT VARCHAR2(2)   := '06' ;    -- �L���ԕi
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '�N' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '��' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '��' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
-- add start ver1.6
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- �x���w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_stck        CONSTANT VARCHAR2(2)  := '20';    -- �o�Ɏ���
-- add end ver1.6
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      fiscal_ym           VARCHAR2(6)                                               -- �Y�ؔN��
     ,dept_code           xxwsh_order_headers_all.performance_management_dept%TYPE  -- �����Ǘ�����
     ,vendor_code         xxwsh_order_headers_all.vendor_code%TYPE                  -- �����
-- 2019/09/11 Ver1.8 Add Start
     ,item_class          xxwsh_order_headers_all.item_class%TYPE                   -- �i�ڋ敪
     ,out_file_type       VARCHAR2(1)                                               -- �o�̓t�@�C���`��(������:0,PDF:1,CSV:2)
     ,out_rep_type        VARCHAR2(1)                                               -- �o�͒��[�`��(������:0,��:1,����:2)
     ,browser             VARCHAR2(1)                                               -- �{����(�ɓ���:1,�����:2)
-- 2019/09/11 Ver1.8 Add End
    ) ;
--
  -- �v�Z���f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
-- mod start ver1.6
--      v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- �����F����於��
      vendor_code           xxwsh_order_headers_all.vendor_code%TYPE -- �����F�����R�[�h
     ,v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- �����F����於��
-- mod end ver1.6
     ,v_zip                 xxcmn_vendors.zip%TYPE                  -- �����F�X�֔ԍ�
     ,v_address_line1       xxcmn_vendors.address_line1%TYPE        -- �����F�Z���P
     ,v_address_line2       xxcmn_vendors.address_line2%TYPE        -- �����F�Z���Q
     ,l_location_name       xxcmn_locations_all.location_name%TYPE  -- ���Ə��F���Ə�����
     ,l_zip                 xxcmn_locations_all.zip%TYPE            -- ���Ə��F�X�֔ԍ�
     ,l_address_line1       xxcmn_locations_all.address_line1%TYPE  -- ���Ə��F�Z���P
     ,l_phone               xxcmn_locations_all.phone%TYPE          -- ���Ə��F�d�b�ԍ�
     ,l_fax                 xxcmn_locations_all.fax%TYPE            -- ���Ə��F�e�`�w�ԍ�
     ,item_class            xxwsh_order_headers_all.item_class%TYPE           -- �i�ڋ敪
-- 2019/09/11 Ver1.8 Add Start
     ,item_class_name       mtl_categories_tl.description%TYPE      -- �i�ڋ敪�i���{��j
-- 2019/09/11 Ver1.8 Add End
     ,arrival_date          xxwsh_order_headers_all.arrival_date%TYPE         -- ���ד�
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--     ,request_no            xxwsh_order_headers_all.request_no%TYPE
     ,request_no            VARCHAR2(13)                                      -- �˗�No�i�`�[�ԍ��j
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
     ,item_code             xxwsh_order_lines_all.shipping_item_code%TYPE     -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE             -- �i�ږ���
     ,unit_price            xxwsh_order_lines_all.unit_price%TYPE             -- �P��
-- 2019/09/11 Ver1.8 Mod Start
--     ,tax_rate              fnd_lookup_values.lookup_code%TYPE                -- ����ŗ�
     ,tax_rate              xxcmm_item_tax_rate_v.tax%TYPE                    -- ����ŗ�
-- 2019/09/11 Ver1.8 Mod End
-- add start ver1.6
     ,amount                NUMBER                                            -- ���z
     ,tax                   NUMBER                                            -- �����
-- add end ver1.6
     ,quantity              xxwsh_order_lines_all.quantity%TYPE               -- �o�׎��ѐ���
-- 2019/09/11 Ver1.8 Add Start
     ,lot_no                xxinv_mov_lot_details.lot_no%TYPE                 -- ���b�gNo
-- 2019/10/18 Ver1.9 Del Start
--     ,bank_name             ap_bank_branches.bank_name%TYPE                   -- ���Z�@�֖�
--     ,bank_bra_name         ap_bank_branches.bank_branch_name%TYPE            -- �x�X��
--     ,bank_acct_type        xxcmn_lookup_values2_v.meaning%TYPE               -- �a���敪��
--     ,bank_acct_num         ap_bank_accounts_all.bank_account_num%TYPE        -- ����No
--     ,bank_acct_name_alt    ap_bank_accounts_all.account_holder_name_alt%TYPE -- �������`��
-- 2019/10/18 Ver1.9 Del End
     ,s_vendor_code         po_vendors.segment1%TYPE                          -- �����F�d����R�[�h
     ,tax_type_code         fnd_lookup_values_vl.lookup_code%TYPE             -- �ŋ敪�i�R�[�h�j
     ,tax_type_name         fnd_lookup_values_vl.description%TYPE             -- �ŋ敪�i���́j
     ,sikyu_date            VARCHAR2(7)                                       -- �L���x���N��
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
     ,billing_office        xxcmn_locations_all.location_name%TYPE            -- �����掖�Ə�
-- 2019/10/18 Ver1.9 Add End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%type ;  -- �c�ƒP��
  gd_fiscal_date_from       DATE ;                                  -- �Ώ۔N����From
  gv_fiscal_date_from_char  VARCHAR2(14) ;                          -- �Ώ۔N����From�i�a��j
  gd_fiscal_date_to         DATE ;                                  -- �Ώ۔N����To
  gv_fiscal_date_to_char    VARCHAR2(14) ;                          -- �Ώ۔N����To�i�a��j
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
  gv_fix_class              fnd_lookup_values.lookup_code%TYPE ;
  gv_shikyu_class           fnd_lookup_values.lookup_code%TYPE ;
-- 2019/09/11 Ver1.8 Add Start
  gv_tax_type_10            fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_8             fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_old_8         fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_no_tax        fnd_lookup_values.lookup_code%TYPE;
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
  gv_l_zip                  fnd_lookup_values.attribute1%TYPE;
  gv_l_address              fnd_lookup_values.attribute2%TYPE;
  gv_l_phone                fnd_lookup_values.attribute3%TYPE;
  gv_l_fax                  fnd_lookup_values.attribute4%TYPE;
  gv_l_dept                 fnd_lookup_values.attribute5%TYPE;
  gv_bank_name              fnd_lookup_values.attribute6%TYPE;
  gv_bank_bra_name          fnd_lookup_values.attribute7%TYPE;
  gv_bank_acct_type         fnd_lookup_values.attribute8%TYPE;
  gv_bank_acct_num          fnd_lookup_values.attribute9%TYPE;
  gv_bank_acct_name_alt     fnd_lookup_values.attribute10%TYPE;
-- 2019/10/18 Ver1.9 Add End
--
  ------------------------------
  -- �v���t�@�C���p
  ------------------------------
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
  gc_prof_mst_org_id        CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID' ; -- �i�ڃ}�X�^�g�D
  gn_prof_mst_org_id        NUMBER ;              -- �i�ڃ}�X�^�g�DID
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
-- 2019/09/11 Ver1.8 Add Start
  gc_prof_title_ito         CONSTANT VARCHAR2(30) := 'XXPO_REP_TITLE_ITO';
  gc_prof_title_ven         CONSTANT VARCHAR2(30) := 'XXPO_REP_TITLE_VEN';
  gv_title_ito              fnd_profile_option_values.profile_option_value%TYPE;
  gv_title_ven              fnd_profile_option_values.profile_option_value%TYPE;
-- 2019/09/11 Ver1.8 Add End
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
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
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
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
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
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
    lv_err_code               VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �Ώ۔N��
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.fiscal_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00004' ;
--      lv_err_code := 'APP-XXPO-10004' ;
      lv_err_code := 'APP-XXPO-10211' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE parameter_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(A-2)
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
    ln_data_cnt           NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code           VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
    lv_token_name1        VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N�����P
    lv_token_name2        VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N�����Q
    lv_token_value1       VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N���l�P
    lv_token_value2       VARCHAR2(100) ;      -- ���b�Z�[�W�g�[�N���l�Q
--
-- 2019/09/11 Ver1.8 Add Start
    -- *** ���[�J���J�[�\�� ***
    CURSOR tax_type_cur
    IS
      SELECT flvv.lookup_code     tax_type_code
            ,flvv.description     tax_type_name
            ,flvv.attribute1      sort
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type   = 'XXPO_TAX_TYPE_CALC'
      AND    gd_fiscal_date_from BETWEEN NVL( flvv.start_date_active, gd_fiscal_date_from )
                                 AND     NVL( flvv.end_date_active  , gd_fiscal_date_from )
      AND    flvv.enabled_flag  = 'Y'
      ORDER BY flvv.attribute1
    ;
--
    -- *** ���[�J�����R�[�h ***
    tax_type_rec  tax_type_cur%ROWTYPE;
--
-- 2019/09/11 Ver1.8 Add End
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
-- 2019/09/11 Ver1.8 Add Start
    tax_type_expt         EXCEPTION;      -- �ŋ敪�擾�G���[
-- 2019/09/11 Ver1.8 Add End
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
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00005' ;
--      lv_err_code := 'APP-XXPO-10005' ;
      lv_err_code := 'APP-XXPO-10212' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �Ώ۔N���擾
    -- ====================================================
    -- �Ώ۔N����From
    gd_fiscal_date_from       := FND_DATE.CANONICAL_TO_DATE( ir_param.fiscal_ym || '01' ) ;
    gv_fiscal_date_from_char  := TO_CHAR( gd_fiscal_date_from, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_from, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_from, 'DD' )   || gc_jp_dd ;
    -- �Ώ۔N����To
    gd_fiscal_date_to         := LAST_DAY( gd_fiscal_date_from ) ;
    gv_fiscal_date_to_char    := TO_CHAR( gd_fiscal_date_to, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_to, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_to, 'DD' )   || gc_jp_dd ;
--
-- 2019/09/11 Ver1.8 Del Start
--    -- ====================================================
--    -- ����Ŏ擾
--    -- ====================================================
--    SELECT COUNT( lookup_code )
--    INTO   ln_data_cnt
--    FROM fnd_lookup_values
--    WHERE gd_fiscal_date_from BETWEEN NVL( START_DATE_ACTIVE, gd_fiscal_date_from )
--                              AND     NVL( END_DATE_ACTIVE  , gd_fiscal_date_from )
--    AND   enabled_flag        = gc_enable_flag
--    AND   language            = gc_language_code
--    AND   source_lang         = gc_language_code
--    AND   lookup_type         = gc_lookup_type_tax_rate
--    ;
--    IF ( ln_data_cnt = 0 ) THEN
---- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
----      lv_err_code := 'APP-XXPO-00005' ;
----      lv_err_code := 'APP-XXPO-10006' ;
--      lv_err_code := 'APP-XXPO-10213' ;
---- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
--      RAISE get_value_expt ;
--    END IF ;
-- 2019/09/11 Ver1.8 Del End
--
    -- ====================================================
    -- �Œ荀�ڂ̒��o
    -- ====================================================
    -- �m��t���O�擾
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_fix_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_kakutei
      AND   flv.lookup_type   = gc_lookup_type_fix_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_fix_class  ;
        lv_token_value2 := gc_lookup_meaning_kakutei ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
    -- �o�׎x���敪
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_shikyu_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_shikyu_irai
      AND   flv.lookup_type   = gc_lookup_type_shikyu_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_shikyu_class  ;
        lv_token_value2 := gc_lookup_meaning_shikyu_irai ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
-- 2019/10/18 Ver1.9 Add Start
    BEGIN
      SELECT attribute1  AS l_zip                 -- �X�֔ԍ�
            ,attribute2  AS l_address             -- �Z��
            ,attribute3  AS l_phone               -- TEL
            ,attribute4  AS l_fax                 -- FAX
            ,attribute5  AS l_dept                -- ���_�i�����j
            ,attribute6  AS bank_name             -- ���Z�@�֖�
            ,attribute7  AS bank_bra_name         -- �x�X��
            ,attribute8  AS bank_acct_type        -- �a���敪
            ,attribute9  AS bank_acct_num         -- ����No
            ,attribute10 AS bank_acct_name_alt    -- �������`
      INTO   gv_l_zip
            ,gv_l_address
            ,gv_l_phone
            ,gv_l_fax
            ,gv_l_dept
            ,gv_bank_name
            ,gv_bank_bra_name
            ,gv_bank_acct_type
            ,gv_bank_acct_num
            ,gv_bank_acct_name_alt
      FROM   fnd_lookup_values flv
      WHERE  gd_exec_date     BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.lookup_type   = gc_lkup_acct_pay
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lkup_acct_pay  ;
        lv_token_value2 := gc_lkup_mean_acct_pay ;
    END;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
-- 2019/10/18 Ver1.9 Add End
--
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    ------------------------------
    -- �i�ڃ}�X�^�g�D�h�c
    ------------------------------
    gn_prof_mst_org_id := FND_PROFILE.VALUE( gc_prof_mst_org_id ) ;
    IF ( gn_prof_mst_org_id IS NULL ) THEN
      lv_err_code     := 'APP-XXCMN-10002' ;
      lv_token_name1  := 'NG_PROFILE' ;
      lv_token_value1 := gc_prof_mst_org_id  ;
      RAISE get_value_expt ;
    END IF ;
--
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
-- 2019/09/11 Ver1.8 Add Start
    ------------------------------
    -- �\��i�ɓ����j
    ------------------------------
    gv_title_ito := FND_PROFILE.VALUE( gc_prof_title_ito );
    IF ( gv_title_ito IS NULL ) THEN
      lv_err_code     := 'APP-XXPO-40053';
      lv_token_name1  := 'NG_PROFILE';
      lv_token_value1 := gc_prof_title_ito;
      RAISE get_value_expt;
    END IF;
--
    ------------------------------
    -- �\��i�����j
    ------------------------------
    gv_title_ven := FND_PROFILE.VALUE( gc_prof_title_ven );
    IF ( gv_title_ven IS NULL ) THEN
      lv_err_code     := 'APP-XXPO-40053';
      lv_token_name1  := 'NG_PROFILE';
      lv_token_value1 := gc_prof_title_ven;
      RAISE get_value_expt;
    END IF;
--
    ------------------------------
    -- �ŋ敪�擾
    ------------------------------
    FOR tax_type_rec IN tax_type_cur LOOP
      IF (tax_type_rec.sort = '1') THEN                     -- �W���ŗ�(10%)
        gv_tax_type_10 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '2') THEN                  -- �y���ŗ�(8%)
        gv_tax_type_8 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '3') THEN                  -- ���W���ŗ�(8%)
        gv_tax_type_old_8 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '4') THEN                  -- �ېőΏۊO
        gv_tax_type_no_tax := tax_type_rec.tax_type_code;
      END IF;
    END LOOP;
--
    -- �ŋ敪���擾�ł��Ȃ��ꍇ
    IF    gv_tax_type_10     IS NULL
      OR  gv_tax_type_8      IS NULL
      OR  gv_tax_type_old_8  IS NULL
      OR  gv_tax_type_no_tax IS NULL
    THEN
      lv_err_code     := 'APP-XXPO-40050';
      RAISE tax_type_expt;
    END IF;
-- 2019/09/11 Ver1.8 Add End
--
  EXCEPTION
-- 2019/09/11 Ver1.8 Add Start
    --*** �ŋ敪�擾�G���[��O ***
    WHEN tax_type_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
-- 2019/09/11 Ver1.8 Add End
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
-- 2019/10/18 Ver1.9 Mod Start
--                    ( iv_application    => gc_application_po
                    ( iv_application    => gc_application_cmn
-- 2019/10/18 Ver1.9 Mod End
                     ,iv_name           => lv_err_code
                     ,iv_token_name1    => lv_token_name1
                     ,iv_token_name2    => lv_token_name2
                     ,iv_token_value1   => lv_token_value1
                     ,iv_token_value2   => lv_token_value2
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
   * Description      : ���׃f�[�^�擾(A-3)
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
        in_vendor_code      xxwsh_order_headers_all.vendor_code%TYPE
       ,in_dept_code        xxwsh_order_headers_all.performance_management_dept%TYPE
-- 2019/09/11 Ver1.8 Add Start
       ,in_item_class       mtl_categories_b.segment1%TYPE
-- 2019/09/11 Ver1.8 Add End
      )
    IS
-- mod start ver1.6
--      SELECT xv.vendor_name     AS v_vendor_name    -- �����F����於��
-- 2019/09/11 Ver1.8 Mod Start
--      SELECT xoha.vendor_code   AS vendor_code      -- �����F�����R�[�h
      SELECT /*+ push_pred(xitrv) */
             xoha.vendor_code   AS vendor_code      -- �����F�����R�[�h
-- 2019/09/11 Ver1.8 Mod End
            ,xv.vendor_name     AS v_vendor_name    -- �����F����於��
-- mod end ver1.6
            ,xv.zip             AS v_zip            -- �����F�X�֔ԍ�
            ,xv.address_line1   AS v_address_line1  -- �����F�Z���P
            ,xv.address_line2   AS v_address_line2  -- �����F�Z���Q
            ,xla.location_name  AS l_location_name  -- ���Ə��F���Ə�����
            ,xla.zip            AS l_zip            -- ���Ə��F�X�֔ԍ�
            ,xla.address_line1  AS l_address_line1  -- ���Ə��F�Z���P
            ,xla.phone          AS l_phone          -- ���Ə��F�d�b�ԍ�
            ,xla.fax            AS l_fax            -- ���Ə��F�e�`�w�ԍ�
            ,mcb.segment1                   AS item_class -- �i�ڋ敪
-- 2019/09/11 Ver1.8 Add Start
            ,mct.description                AS item_class_name  -- �i�ڋ敪�i���{��j
-- 2019/09/11 Ver1.8 Add End
            ,xoha.arrival_date              AS arrival_date -- ���ד�
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--            ,xoha.request_no                AS request_no   -- �˗�No�i�`�[�ԍ��j
            ,CASE otta.attribute11
               WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
               ELSE                              xoha.request_no
             END                AS request_no   -- �˗�No�i�`�[�ԍ��j
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
            ,xola.shipping_item_code        AS item_code    -- �i�ڃR�[�h
            ,ximb.item_short_name           AS item_name    -- �i�ږ���
            ,xola.unit_price                AS unit_price   -- �P��
-- 2019/09/11 Ver1.8 Mod Start
--            ,TO_NUMBER( flv.lookup_code )   AS tax_rate     -- ����ŗ�
            ,TO_NUMBER( xitrv.tax )         AS tax_rate     -- ����ŗ�
-- 2019/09/11 Ver1.8 Mod End
-- add start ver1.6
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price))        AS amount       -- ���z
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
-- 2019/09/11 Ver1.8 Mod Start
--             END * xola.unit_price * TO_NUMBER( flv.lookup_code ) / 100)) AS tax -- �����
             END * xola.unit_price * TO_NUMBER( xitrv.tax ) / 100)) AS tax -- �����
-- 2019/09/11 Ver1.8 Mod End
-- add start ver1.6
-- mod start ver1.6
--            ,CASE
            ,SUM(CASE
-- 2008/12/05 v1.5 T.Yoshimoto Mod Start �{��#446
              --WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.quantity
--              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.shipped_quantity
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
-- 2008/12/05 v1.5 T.Yoshimoto Mod End �{��#446
--              WHEN ( otta.order_category_code = 'RETURN' ) THEN xola.quantity * -1
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
--             END quantity                           -- �o�׎��ѐ���
             END) quantity                           -- �o�׎��ѐ���
-- 2019/09/11 Ver1.8 Add Start
            ,xmld.lot_no                    AS lot_no                   -- ���b�gNo
-- 2019/10/18 Ver1.9 Del Start
--            ,abb.bank_name                  AS bank_name                -- ���Z�@�֖�
--            ,abb.bank_branch_name           AS bank_branch_name         -- �x�X��
--            ,flv.meaning                    AS bank_account_type        -- �a���敪��
--            ,aba.bank_account_num           AS bank_account_num         -- ����No
--            ,aba.account_holder_name_alt    AS bank_account_name_alt    -- �������`��
-- 2019/10/18 Ver1.9 Del End
            ,pv.segment1                    AS s_vendor_code            -- �����F�d����R�[�h
            ,flvv.lookup_code               AS tax_type_code            -- �ŋ敪�i�R�[�h�j
            ,flvv.description               AS tax_type_name            -- �ŋ敪�i���́j
            ,TO_CHAR(xoha.sikyu_return_date, 'YYYY/MM')
                                            AS sikyu_date               -- �L���x���N��
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
            ,xla2.location_name             AS billing_office           -- �����掖�Ə�
-- 2019/10/18 Ver1.9 Add End
-- mod end ver1.6
      FROM xxwsh_order_headers_all    xoha    -- �󒍃w�b�_�A�h�I��
          ,oe_transaction_types_all   otta    -- �󒍃^�C�v
          ,xxcmn_vendors              xv      -- �d����A�h�I��
          ,hr_locations_all           hla     -- ���Ə��}�X�^
          ,xxcmn_locations_all        xla     -- ���Ə��A�h�I��
          ,xxwsh_order_lines_all      xola    -- �󒍖��׃A�h�I��
-- add start ver1.6
          ,xxinv_mov_lot_details      xmld    -- �ړ����b�g�ڍ׃A�h�I��
-- add end ver1.6
          ,xxcmn_item_mst_b           ximb    -- �i�ڃA�h�I��
          ,gmi_item_categories        gic     -- �i�ڃJ�e�S������
          ,mtl_categories_b           mcb     -- �i�ڃJ�e�S��
          ,mtl_category_sets_b        mcsb    -- �i�ڃJ�e�S���Z�b�g
          ,mtl_category_sets_tl       mcst    -- �i�ڃJ�e�S���Z�b�g�i���{��j
-- 2019/09/11 Ver1.8 Del Start
--          ,fnd_lookup_values          flv     -- �N�C�b�N�R�[�h�i����Łj
-- 2019/09/11 Ver1.8 Del End
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
          ,ic_item_mst_b              iimb    -- �n�o�l�i�ڃ}�X�^
          ,mtl_system_items_b         msib    -- �h�m�u�i�ڃ}�X�^
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
-- 2019/09/11 Ver1.8 Add Start
          ,xxcmm_item_tax_rate_v      xitrv       -- ����ŗ�VIEW
-- 2019/10/18 Ver1.9 Del Start
--          ,ap_bank_account_uses_all   abaua       -- �����g�p���e�[�u��
--          ,ap_bank_accounts_all       aba         -- ��s����
--          ,ap_bank_branches           abb         -- ��s�x�X
-- 2019/10/18 Ver1.9 Del End
          ,po_vendors                 pv          -- �d����
          ,po_vendor_sites_all        pvsa_sales  -- �d����T�C�g(�c��)
          ,po_vendor_sites_all        pvsa_mfg    -- �d����T�C�g(���Y)
-- 2019/10/18 Ver1.9 Del Start
--          ,xxcmn_lookup_values2_v     flv         -- �N�C�b�N�R�[�h�i������ʁj
-- 2019/10/18 Ver1.9 Del End
          ,mtl_categories_tl          mct         -- �i�ڃJ�e�S���i���{��j
          ,fnd_lookup_values_vl       flvv        -- �N�C�b�N�R�[�h�i�ŋ敪�j
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
          ,hr_locations_all           hla2    -- ���Ə��}�X�^�i�����Ǘ������j
          ,xxcmn_locations_all        xla2    -- ���Ə��A�h�I���i�����Ǘ������j
-- 2019/10/18 Ber1.9 Add End
      WHERE mcsb.structure_id     = mcb.structure_id
      AND   gic.category_id       = mcb.category_id
      ---------------------------------------------------------------------------------------------
      -- �i�ڃJ�e�S���Z�b�g�̍i���ݏ���
      AND   mcst.category_set_name    = gc_cat_set_item_class
      AND   mcst.source_lang          = gc_language_code
      AND   mcst.language             = gc_language_code
      AND   mcsb.category_set_id      = mcst.category_set_id
      AND   gic.category_set_id       = mcsb.category_set_id
      AND   ximb.item_id              = gic.item_id
-- 2019/09/11 Ver1.8 Add Start
      AND   mcb.category_id           = mct.category_id
      AND   mct.source_lang           = gc_language_code
      AND   mct.language              = gc_language_code
      AND   (  in_item_class          IS NULL                        -- �i�ڋ敪 = NULL
            OR mcb.segment1           = in_item_class )              -- �i�ڋ敪
-- 2019/09/11 Ver1.8 Add End
      ---------------------------------------------------------------------------------------------
-- 2019/09/11 Ver1.8 Mod Start
--      -- �N�C�b�N�R�[�h�i����Łj�̍i���ݏ���
--      AND   xoha.arrival_date         BETWEEN NVL( flv.start_date_active, xoha.arrival_date )
--                                      AND     NVL( flv.end_date_active  , xoha.arrival_date )
--      AND   flv.language              = gc_language_code
--      AND   flv.source_lang           = gc_language_code
--      AND   flv.lookup_type           = gc_lookup_type_tax_rate
      -- ����ŗ�VIEW�̍i���ݏ���
      AND   NVL( xoha.sikyu_return_date, xoha.arrival_date )  BETWEEN NVL( xitrv.start_date_active, NVL( xoha.sikyu_return_date, xoha.arrival_date ) )
                                                              AND     NVL( xitrv.end_date_active  , NVL( xoha.sikyu_return_date, xoha.arrival_date ) )
      AND   msib.segment1             = xitrv.item_no
-- 2019/09/11 Ver1.8 Mod End
      ---------------------------------------------------------------------------------------------
      -- �i�ڃA�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN ximb.start_date_active  -- ���ד��ŗL���ȃf�[�^
                                      AND     ximb.end_date_active    -- 
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      AND   xola.shipping_inventory_item_id = ximb.item_id
      AND   iimb.item_id                    = ximb.item_id
      AND   msib.segment1                   = iimb.item_no
      AND   msib.organization_id            = gn_prof_mst_org_id
      AND   xola.shipping_inventory_item_id = msib.inventory_item_id
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      AND   xola.delete_flag          = 'N'
      AND   xoha.order_header_id      = xola.order_header_id
-- add start ver1.6
      AND   xola.order_line_id        = xmld.mov_line_id
      AND   xmld.document_type_code   = gc_doc_type_prov
      AND   xmld.record_type_code     = gc_rec_type_stck
-- add end ver1.6
      ---------------------------------------------------------------------------------------------
      -- ���Ə��A�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN xla.start_date_active     -- ���ד��ŗL���ȃf�[�^
                                      AND     xla.end_date_active       -- 
      AND   hla.location_id           = xla.location_id
-- 2009/03/04 v1.7 UPDATE START
--      AND   xoha.performance_management_dept
      AND xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID)
-- 2009/03/04 v1.7 UPDATE END
                                      = hla.location_code
      ---------------------------------------------------------------------------------------------
      -- �d����A�h�I���̍i���ݏ���
      AND   xoha.arrival_date         BETWEEN xv.start_date_active(+)   -- ���ד��ŗL���ȃf�[�^
                                      AND     xv.end_date_active(+)     -- 
      AND   xoha.vendor_id            = xv.vendor_id(+)
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v�̍i���ݏ���
      AND   otta.org_id               = gn_sales_class              -- �c�ƒP��    ��Profile
      AND   otta.attribute1           = gv_shikyu_class             -- �o�׎x���敪���x���˗�
      AND   xoha.order_type_id        = otta.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I���̍i���ݏ���
      AND   (  in_dept_code          IS NULL                        -- ���Ə����w��̎��Ə�
            OR xoha.performance_management_dept                     -- 
                                      = in_dept_code )              -- 
      AND   (  in_vendor_code        IS NULL                        -- ����恁�w��̎����
            OR xoha.vendor_code       = in_vendor_code )            -- 
      AND   xoha.amount_fix_class     = gv_fix_class                -- �L�����z�m��敪���m��
      AND   xoha.latest_external_flag = 'Y'                         -- �ŐV�t���O      ���ŐV
      AND   xoha.arrival_date         BETWEEN gd_fiscal_date_from   -- ���ד����Y�ؔN���Ɋ܂܂��
                                      AND     gd_fiscal_date_to     -- 
-- 2019/09/11 Ver1.8 Add Start
      ---------------------------------------------------------------------------------------------
      -- �U������̍i���ݏ���
-- 2019/10/18 Ver1.9 Del Start
--      AND   abaua.external_bank_account_id = aba.bank_account_id
--      AND   aba.bank_branch_id             = abb.bank_branch_id
--      AND   xoha.arrival_date              BETWEEN abaua.start_date
--                                           AND     NVL(abaua.end_date ,xoha.arrival_date)
--      AND   abaua.vendor_id                = pv.vendor_id
--      AND   abaua.vendor_id                = pvsa_sales.vendor_id
--      AND   abaua.vendor_site_id           = pvsa_sales.vendor_site_id
-- 2019/10/18 Ver1.9 Del End
-- 2019/10/18 Ver1.9 Add Start
      AND   pv.vendor_id                   = pvsa_sales.vendor_id
-- 2019/10/18 Ver1.9 Add End
      AND   pvsa_sales.org_id              = FND_PROFILE.VALUE( 'XXCMN_SALES_ORG_ID' )
      AND   pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
      AND   pvsa_mfg.org_id                = gn_sales_class
      AND   pvsa_mfg.vendor_site_code      = xoha.vendor_site_code
-- 2019/10/18 Ver1.9 Del Start
--      AND   aba.bank_account_type          = flv.lookup_code
--      AND   flv.lookup_type                = 'XXCSO1_KOZA_TYPE'
--      AND   xoha.arrival_date              BETWEEN flv.start_date_active
--                                           AND     NVL(flv.end_date_active ,xoha.arrival_date)
-- 2019/10/18 Ver1.9 Del End
      ---------------------------------------------------------------------------------------------
      -- �ŋ敪�̍i���ݏ���
      AND   flvv.lookup_type               = 'XXPO_TAX_TYPE_CALC'    -- �ŋ敪�i���̗p�j
      AND   flvv.lookup_code               = xitrv.tax_code_ex       -- �d���E�O��
      AND   flvv.enabled_flag              = 'Y'
      AND   xoha.arrival_date              BETWEEN flvv.start_date_active   -- ���ד��ŗL���ȃf�[�^
                                           AND     NVL(flvv.end_date_active, xoha.arrival_date)   -- 
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
      ---------------------------------------------------------------------------------------------
      -- �����掖�Ə��̏���
      AND   hla2.location_code        = xoha.performance_management_dept  -- ���ъǗ�����
      AND   hla2.location_id          = xla2.location_id
      AND   xoha.arrival_date         BETWEEN xla2.start_date_active      -- ���ד��ŗL���ȃf�[�^
                                      AND     xla2.end_date_active
-- 2019/10/18 Ver1.9 Add End
-- add start ver1.6
      GROUP BY xoha.vendor_code         -- �����F�����R�[�h
              ,xv.vendor_name           -- �����F����於��
              ,xv.zip                   -- �����F�X�֔ԍ�
              ,xv.address_line1         -- �����F�Z���P
              ,xv.address_line2         -- �����F�Z���Q
              ,xla.location_name        -- ���Ə��F���Ə�����
              ,xla.zip                  -- ���Ə��F�X�֔ԍ�
              ,xla.address_line1        -- ���Ə��F�Z���P
              ,xla.phone                -- ���Ə��F�d�b�ԍ�
              ,xla.fax                  -- ���Ə��F�e�`�w�ԍ�
              ,mcb.segment1             -- �i�ڋ敪
-- 2019/09/11 Ver1.8 Add Start
              ,mct.description          -- �i�ڋ敪�i���́j
-- 2019/09/11 Ver1.8 Add End
              ,xoha.arrival_date        -- ���ד�
              ,CASE otta.attribute11
                WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
                ELSE           xoha.request_no
               END                          -- �˗�No�i�`�[�ԍ��j
              ,xola.shipping_item_code      -- �i�ڃR�[�h
              ,ximb.item_short_name         -- �i�ږ���
              ,xola.unit_price              -- �P��
-- 2019/09/11 Ver1.8 Mod Start
--              ,TO_NUMBER( flv.lookup_code ) -- ����ŗ�
              ,TO_NUMBER( xitrv.tax )       -- ����ŗ�
-- 2019/09/11 Ver1.8 Mod End
-- 2019/09/11 Ver1.8 Add Start
              ,xmld.lot_no                  -- ���b�gNo
-- 2019/10/18 Ver1.9 Del Start
--              ,abb.bank_name                -- ���Z�@�֖�
--              ,abb.bank_branch_name         -- �x�X��
--              ,flv.meaning                  -- �a���敪��
--              ,aba.bank_account_num         -- ����No
--              ,aba.account_holder_name_alt  -- �������`��
-- 2019/10/18 Ver1.9 Del End
              ,pv.segment1                  -- �����F�d����R�[�h
              ,flvv.lookup_code             -- �ŋ敪
              ,flvv.description             -- �ŋ敪�i���́j
              ,TO_CHAR(xoha.sikyu_return_date, 'YYYY/MM')
                                            -- �L���x���N��
-- 2019/10/18 Ver1.9 Add Start
              ,xla2.location_name           -- �����掖�Ə�
-- 2019/10/18 Ver1.9 Add End
-- 2019/09/11 Ver1.8 Add End
-- add end ver1.6
      ORDER BY xoha.vendor_code         -- �����R�[�h
              ,mcb.segment1             -- �i�ڋ敪
              ,xoha.arrival_date        -- ���ד�
              ,xola.shipping_item_code  -- �i�ڃR�[�h
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
        ir_param.vendor_code    -- �����R�[�h
       ,ir_param.dept_code      -- �����Ǘ�����
-- 2019/09/11 Ver1.8 Add Start
       ,ir_param.item_class     -- �i�ڋ敪
-- 2019/09/11 Ver1.8 Add End
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
--
  EXCEPTION
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
-- 2019/09/11 Ver1.8 Add Start
  /**********************************************************************************
   * Procedure Name   : prc_ins_data
   * Description      : TEMP�e�[�u���f�[�^�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE prc_ins_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,it_data_rec   IN  tab_data_type_dtl         -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_data'; -- �v���O������
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
    -- �f�[�^�o�^
    -- ====================================================
      FOR i IN 1..it_data_rec.count LOOP
        INSERT INTO xxpo_invoice_work(
          request_id                      -- 01.�v��ID
         ,vendor_code                     -- 02.�����R�[�h
         ,vendor_name                     -- 03.����於
         ,zip                             -- 04.�X�֔ԍ�
         ,address                         -- 05.�Z��
         ,arrival_date                    -- 06.���t
         ,slip_num                        -- 07.�`�[No
         ,lot_no                          -- 08.���b�gNo
         ,dept_name                       -- 09.�����Ǘ�����
         ,item_class                      -- 10.�i�ڋ敪
         ,item_class_name                 -- 11.�i�ڋ敪����
         ,item_code                       -- 12.�i�ڃR�[�h
         ,item_name                       -- 13.�i�ږ���
         ,quantity                        -- 14.����
         ,unit_price                      -- 15.�P��
         ,amount                          -- 16.�Ŕ����z
         ,tax                             -- 17.����Ŋz
         ,tax_type                        -- 18.�ŋ敪
         ,tax_include                     -- 19.�ō����z
         ,yusyo_year_month                -- 20.�L���N��
        ) VALUES (
          gn_request_id                   -- 01.�v��ID
         ,it_data_rec(i).vendor_code      -- 02.�����F�����R�[�h
         ,it_data_rec(i).v_vendor_name    -- 03.�����F����於��
         ,it_data_rec(i).v_zip            -- 04.�����F�X�֔ԍ�
         ,it_data_rec(i).v_address_line1 || it_data_rec(i).v_address_line2
                                          -- 05.�����F�Z���P || �����F�Z���Q
         ,it_data_rec(i).arrival_date     -- 06.���ד�
         ,it_data_rec(i).request_no       -- 07.�˗�No�i�`�[�ԍ��j
         ,it_data_rec(i).lot_no           -- 08.���b�gNo
-- 2019/10/18 Ver1.9 Del Start
--         ,it_data_rec(i).l_location_name  -- 09.���Ə��F���Ə�����
         ,it_data_rec(i).billing_office   -- 09.�����掖�Ə�
-- 2019/10/18 Ver1.9 Del End
         ,it_data_rec(i).item_class       -- 10.�i�ڋ敪�i���{��j
         ,it_data_rec(i).item_class_name  -- 11.�i�ڋ敪�i���{��j
         ,it_data_rec(i).item_code        -- 12.�i�ڃR�[�h
         ,it_data_rec(i).item_name        -- 13.�i�ږ���
         ,it_data_rec(i).quantity         -- 14.����
         ,it_data_rec(i).unit_price       -- 15.�P��
         ,it_data_rec(i).amount           -- 16.���z�i�Ŕ��j
         ,it_data_rec(i).tax              -- 17.����Ŋz
         ,it_data_rec(i).tax_type_name    -- 18.�ŋ敪�i���́j
         ,it_data_rec(i).amount + it_data_rec(i).tax
                                          -- 19.�Ŕ����z + ����Ŋz
         ,it_data_rec(i).sikyu_date       -- 20.�L���x���N��
        );
      END LOOP;
--
    -- �G���[���Ȃ����COMMIT�i�ďo��Ńf�[�^���o���邽�߁j
    COMMIT;
--
  EXCEPTION
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
  END prc_ins_data ;
-- 2019/09/11 Ver1.8 Add End
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_break_init           VARCHAR2(100) := '*' ;  -- ����於
    lc_break_null           VARCHAR2(100) := '**' ;  -- �i�ڋ敪
--
-- 2019/09/11 Ver1.8 Add Start
    --�v���̔��s
    cv_application          CONSTANT VARCHAR2(5)   := 'XXPO';           -- Application
    cv_program              CONSTANT VARCHAR2(13)  := 'XXPO780002C';    -- ���������L���x�����E�m�F��CSV�o��
    cv_description          CONSTANT VARCHAR2(9)   := NULL;             -- Description
    cv_start_time           CONSTANT VARCHAR2(10)  := NULL;             -- Start_time
    cb_sub_request          CONSTANT BOOLEAN       := FALSE;            -- Sub_request
    -- �g�[�N��
    cv_tkn_request_id       CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
-- 2019/09/11 Ver1.8 Add End
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_vendor_name          VARCHAR2(100) := '*' ;  -- ����於
    lv_item_class           VARCHAR2(100) := '*' ;  -- �i�ڋ敪
--
    -- ���z�v�Z�p
    ln_amount               NUMBER := 0 ;         -- �v�Z�p�F���z
    ln_tax                  NUMBER := 0 ;         -- �v�Z�p�F�����
-- 2019/09/11 Ver1.8 Del Start
--    ln_balance              NUMBER := 0 ;         -- �v�Z�p�F�L���z
--    ln_ttl_amount           NUMBER := 0 ;         -- ����L�����z
--    ln_ttl_tax              NUMBER := 0 ;         -- �������œ�
--    ln_ttl_balance          NUMBER := 0 ;         -- ����L���z
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
    ln_amount_10            NUMBER := 0;          -- �Ŕ����z�i�W���ŗ�(10%)�j
    ln_tax_10               NUMBER := 0;          -- ����Ŋz�i�W���ŗ�(10%)�j
    ln_amount_8             NUMBER := 0;          -- �Ŕ����z�i�y���ŗ�(8%)�j
    ln_tax_8                NUMBER := 0;          -- ����Ŋz�i�y���ŗ�(8%)�j
    ln_amount_old_8         NUMBER := 0;          -- �Ŕ����z�i���W���ŗ�(8%)�j
    ln_tax_old_8            NUMBER := 0;          -- ����Ŋz�i���W���ŗ�(8%)�j
    ln_amount_no_tax        NUMBER := 0;          -- �ېőΏۊO
    ln_no_tax               NUMBER := 0;          -- �ېőΏۊO
    ln_request_id           NUMBER;               -- �v��ID�i�ďo��j
-- 2019/09/11 Ver1.8 Add End
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--  
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
-- 2019/09/11 Ver1.8 Add Start
    -- �p�����[�^.�o�̓t�@�C���`���� ������(0) ���� CSV(2)�̏ꍇ��A-6�AA-7���N��
    IF (  ir_param.out_file_type = '0'
      OR  ir_param.out_file_type = '2')
    THEN
      -- =====================================================
      -- A-6. TEMP�e�[�u���f�[�^�o�^
      -- =====================================================
      prc_ins_data(
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,it_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt ;
      END IF;
--
      -- =====================================================
      -- A-7. CSV�o�͏����N��
      -- =====================================================
--
      -- ���������L���x�����E�m�F��CSV�o��(XXPO780002C)�̋N��
      ln_request_id := fnd_request.submit_request(
                          application  => cv_application        -- �A�v���P�[�V����
                         ,program      => cv_program            -- �v���O����
                         ,description  => cv_description        -- �K�p
                         ,start_time   => cv_start_time         -- �J�n����
                         ,sub_request  => cb_sub_request        -- �T�u�v��
                         ,argument1    => gn_request_id         -- �v��ID
                       );
      -- �v���̔��s�Ɏ��s�����ꍇ
      IF ( ln_request_id = 0 ) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gc_application_po
                       ,iv_name         => 'APP-XXPO-40051'
                       ,iv_token_name1  => cv_tkn_request_id         -- �v��ID
                       ,iv_token_value1 => TO_CHAR( ln_request_id )  -- �v��ID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
    END IF;
-- 2019/09/11 Ver1.8 Add End
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �����k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vender_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- ����於�̃u���C�N
      -- =====================================================
      -- ����於�̂��؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).v_vendor_name, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �W�v�l�o��
          ------------------------------
-- 2019/09/11 Ver1.8 Del Start
--          -- ����L�����z
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
--          -- �������œ�
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
--          -- ����L���z
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
          -- �Ŕ����z(�W���ŗ�(10%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_10';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_10;
          -- ����Ŋz(�W���ŗ�(10%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_10';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_10;
          -- �Ŕ����z(�y���ŗ�(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_8;
          -- ����Ŋz(�y���ŗ�(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_8;
          -- �Ŕ����z(���W���ŗ�(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_old_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_old_8;
          -- ����Ŋz(���W���ŗ�(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_old_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_old_8;
          -- �Ŕ����z(�ېőΏۊO)
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_no_tax';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_no_tax;
          -- ����Ŋz(�ېőΏۊO)
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'no_tax';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_no_tax;
-- 2019/09/11 Ver1.8 Add End
          ------------------------------
          -- �����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ����悪�擾�ł��Ȃ��ꍇ�A�X�e�[�^�X���x���ɐݒ�
        IF ( gt_main_data(i).v_vendor_name IS NULL ) THEN
          ov_retcode := gv_status_warn ;
        END IF ;

        -- -----------------------------------------------------
        -- �����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vender' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
-- 2019/09/11 Ver1.8 Add Start
        -- ------------------------------------------------------
        -- �ӗp�^�O�o��
        ---------------------------------------------------------
        -- �p�����[�^�F�o�͒��[�`��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'p_rep_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ir_param.out_rep_type;
        -- �Ӄ^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := CASE ir_param.browser
                                                     WHEN '1' THEN gv_title_ito
                                                     ELSE          gv_title_ven
                                                   END;
-- 2019/09/11 Ver1.8 Add End
        -- ���[�h�c
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
        -- ���{��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
--
        -- �����F�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_zip ;
        -- �����F�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line1 ;
        -- �����F�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line2 ;
        -- �����F����於�̂P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 ) ;
                                      := SUBSTRB( gt_main_data(i).v_vendor_name,  1, 40 ) ;
-- 2019/09/11 Ver1.8 Mod End
        -- �����F����於�̂Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 ) ;
                                      := SUBSTRB( gt_main_data(i).v_vendor_name, 41, 20 ) ;
-- 2019/09/11 Ver1.8 Mod End
--
        -- ����From
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_from' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_from_char ;
        -- ����To
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_to' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_to_char ;
        -- ���Ə��F�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_zip;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- ���Ə��F�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).l_address_line1,  1, 15 ) ;
                                      := SUBSTRB( gt_main_data(i).l_address_line1,  1, 30 ) ;
-- 2019/09/11 Ver1.8 Mod End
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_l_address,  1, 30 ) ;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- ���Ə��F�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).l_address_line1, 16, 15 ) ;
                                      := SUBSTRB( gt_main_data(i).l_address_line1, 31, 30 ) ;
-- 2019/09/11 Ver1.8 Mod End
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_l_address, 31, 30 ) ;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- ���Ə��F�d�b�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_phone_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_phone;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- ���Ə��F�e�`�w�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_fax;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- ���Ə��F���Ə�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.6
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value 
--                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
        --�y�{���ҁF�ɓ����z�̏ꍇ
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value 
                                       := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
        ELSE
        --�y�{���ҁF�����z�̏ꍇ
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_dept;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
-- mod end ver1.6
-- 2019/09/11 Ver1.8 Add Start
        -- ���Ə��F�����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_ven_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_code;
        -- ���Ə��F�d����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_s_ven_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).s_vendor_code;
        ------------------------------------------------------
        -- �U������
        ------------------------------------------------------
        -- ���Z�@�֖�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_name;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_name;
-- 2019/10/18 Mod Ver1.9 End
        -- �x�X��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_bra_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_bra_name;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_bra_name;
-- 2019/10/18 Mod Ver1.9 End
        -- �a���敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_acct_type;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_acct_type;
-- 2019/10/18 Mod Ver1.9 End
        -- ����No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_num';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_acct_num;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_acct_num;
-- 2019/10/18 Mod Ver1.9 End
        -- �������`��1
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 1, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 1, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- �������`��2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 31, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 31, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- �������`��3
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt3';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 61, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 61, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- �������`��4
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt4';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 91, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 91, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- �������`��5
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt5';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 121, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 121, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
-- 2019/09/11 Ver1.8 Add End
--
        ------------------------------
        -- ���ׂk�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_class_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_vendor_name  := NVL( gt_main_data(i).v_vendor_name, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
        -- �W�v�ϐ��O�N���A
-- 2019/09/11 Ver1.8 Del Start
--        ln_ttl_amount   := 0 ;  -- ����L�����z
--        ln_ttl_tax      := 0 ;  -- �������œ�
--        ln_ttl_balance  := 0 ;  -- ����L���z
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
        ln_amount_10      := 0;   -- �Ŕ����z�i�W���ŗ�(10%)�j
        ln_tax_10         := 0;   -- ����Ŋz�i�W���ŗ�(10%)�j
        ln_amount_8       := 0;   -- �Ŕ����z�i�y���ŗ�(8%)�j
        ln_tax_8          := 0;   -- ����Ŋz�i�y���ŗ�(8%)�j
        ln_amount_old_8   := 0;   -- �Ŕ����z�i���W���ŗ�(8%)�j
        ln_tax_old_8      := 0;   -- ����Ŋz�i���W���ŗ�(8%)�j
        ln_amount_no_tax  := 0;   -- �ېőΏۊO
        ln_no_tax         := 0;   -- �ېőΏۊO
-- 2019/09/11 Ver1.8 Add End
--
      END IF ;
--
      -- =====================================================
      -- �i�ڋ敪�u���C�N
      -- =====================================================
      -- �i�ڋ敪���؂�ւ�����ꍇ
      IF ( gt_main_data(i).item_class <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_class' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
-- 2019/09/11 Ver1.8 Add Start
        -- �i�ڋ敪(�w�b�_���j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class_name;
        -- -----------------------------------------------------
        -- ���׃w�b�_�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_list_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- ���׃w�b�_�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_list';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- ���׃w�b�_�o��
        -- -----------------------------------------------------
        -- ���׃^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_title_ven;
        -- ���[�h�c
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_report_id';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
        -- ���{��
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_exec_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format );
        -- �����F�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_zip_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_zip;
        -- �����F�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_address1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line1;
        -- �����F�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_address2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line2;
        -- �����F����於�̂P
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_name1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 );
        -- �����F����於�̂Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_name2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 );
        -- ����From
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_period_from';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_from_char;
        -- ����To
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_period_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_to_char;
        -- -----------------------------------------------------
        -- ���׃w�b�_�f�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_list';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- ���׃w�b�_�k�f�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_list_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
-- 2019/09/11 Ver1.8 Add End
-- 2019/09/11 Ver1.8 Del Start
--        -- -----------------------------------------------------
--        -- �����f�f�[�^�^�O�o��
--        -- -----------------------------------------------------
--        -- �i�ڋ敪
--        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class' ;
--        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class ;
-- 2019/09/11 Ver1.8 Del End
        -- -----------------------------------------------------
        -- ���ׂk�f�J�n�^�O
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class   := gt_main_data(i).item_class ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      -- -----------------------------------------------------
      -- �v�Z���ڂ̎Z�o
      -- -----------------------------------------------------
      -- �ʌv�Z����
-- mod start ver1.6
--      ln_amount   := ROUND( gt_main_data(i).quantity * gt_main_data(i).unit_price ) ;
--      ln_tax      := ROUND( ln_amount * gt_main_data(i).tax_rate / 100 ) ;
-- 2019/09/11 Ver1.8 Del Start
--      ln_amount   := gt_main_data(i).amount;
--      ln_tax      := gt_main_data(i).tax;
---- mod end ver1.6
---- 2008/06/20 v1.3 Y.Yamamoto Update Start
----      ln_balance  := ln_amount - ln_tax ;
--      ln_balance  := ln_amount + ln_tax ;
---- 2008/06/20 v1.3 Y.Yamamoto Update End
----
--      -- �W�v����
--      ln_ttl_amount  := ln_ttl_amount  + ln_amount ;  -- ����L�����z
--      ln_ttl_tax     := ln_ttl_tax     + ln_tax ;     -- �������œ�
--      ln_ttl_balance := ln_ttl_balance + ln_balance ; -- ����L���z
--
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
      -- �W�v����
      -- �ŋ敪���W���ŗ�(10%)
      IF ( gv_tax_type_10 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_10      := ln_amount_10 + gt_main_data(i).amount;
        ln_tax_10         := ln_tax_10 + gt_main_data(i).tax;
      -- �ŋ敪���y���ŗ�(8%)
      ELSIF ( gv_tax_type_8 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_8       := ln_amount_8 + gt_main_data(i).amount;
        ln_tax_8          := ln_tax_8 + gt_main_data(i).tax;
      -- �ŋ敪�����W���ŗ�(8%)
      ELSIF ( gv_tax_type_old_8 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_old_8   := ln_amount_old_8 + gt_main_data(i).amount;
        ln_tax_old_8      := ln_tax_old_8 + gt_main_data(i).tax;
      -- �ŋ敪���ېőΏۊO
      ELSIF ( gv_tax_type_no_tax = gt_main_data(i).tax_type_code ) THEN
        ln_amount_no_tax  := ln_amount_no_tax + gt_main_data(i).amount;
        ln_no_tax         := ln_no_tax + gt_main_data(i).tax;
      END IF;
--
-- 2019/09/11 Ver1.8 Add End
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���ד�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
-- 2019/09/11 Ver1.8 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'date' ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date';
-- 2019/09/11 Ver1.8 Mod End
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).arrival_date, gc_char_d_format ) ;
-- 2019/09/11 Ver1.8 Mod Start
      -- �L���N��
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sikyu_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).sikyu_date;
-- 2019/09/11 Ver1.8 Mod End
      -- �`�[�ԍ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'slip_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
-- 2019/09/11 Ver1.8 Add Start
      -- �����Ǘ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'l_location_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Ver1.9 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).billing_office;
-- 2019/10/18 Ver1.9 Mod End
      -- �i�ڋ敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class_name;
-- 2019/09/11 Ver1.8 Add End
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_name ;
      -- �o�׎��ѐ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).quantity ;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_price ;
      -- ���z
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/09/11 Ver1.8 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_value := ln_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).amount;
-- 2019/09/11 Ver1.8 Mod End
-- 2019/09/11 Ver1.8 Add Start
      -- ����Ŋz
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tax';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).tax;
      -- �ŋ敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_type';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).tax_type_name;
-- 2019/09/11 Ver1.8 Add End
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �W�v�l�o��
    ------------------------------
-- 2019/09/11 Ver1.8 Mod Start
--    -- ����L�����z
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
--    -- �������œ�
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
--    -- ����L���z
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
    -- �L���x�����z(�Ŕ�)(�W���ŗ�(10%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_10';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_10;
    -- ����Ŋz(�W���ŗ�(10%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_10';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_10;
    -- �L���x�����z(�Ŕ�)(�y���ŗ�(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_8;
    -- ����Ŋz(�y���ŗ�(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_8;
    -- �L���x�����z(�Ŕ�)(���W���ŗ�(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_old_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_old_8;
    -- ����Ŋz(���W���ŗ�(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_old_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_old_8;
    -- �L���x�����z(�Ŕ�)(�ېőΏۊO)
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_no_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_no_tax;
    -- ����Ŋz(�ېőΏۊO)
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'no_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_no_tax;
-- 2019/09/11 Ver1.8 Mod End
    ------------------------------
    -- �����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vender_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,'APP-XXCMN-10122'  ) ;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_fiscal_ym          IN     VARCHAR2         --   01 : �Y�ؔN��
     ,iv_dept_code          IN     VARCHAR2         --   02 : �����Ǘ�����
     ,iv_vendor_code        IN     VARCHAR2         --   03 : �����
-- 2019/09/11 Ver1.8 Add Start
     ,iv_item_class         IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_out_file_type      IN     VARCHAR2         --   05 : �o�̓t�@�C���`��
     ,iv_out_rep_type       IN     VARCHAR2         --   06 : �o�͒��[�`��
     ,iv_browser            IN     VARCHAR2         --   07 : �{����
-- 2019/09/11 Ver1.8 Add End
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
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
    gv_report_id              := 'XXPO780001T' ;      -- ���[ID
    gd_exec_date              := SYSDATE ;            -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.fiscal_ym    := iv_fiscal_ym ;       -- �Y�ؔN��
    lr_param_rec.dept_code    := iv_dept_code ;       -- �����Ǘ�����
    lr_param_rec.vendor_code  := iv_vendor_code ;     -- �����
-- 2019/09/11 Ver1.8 Add Start
    lr_param_rec.item_class    := iv_item_class;              -- �i�ڋ敪
    lr_param_rec.out_file_type := NVL(iv_out_file_type, '0'); -- �o�̓t�@�C���`��
    lr_param_rec.out_rep_type  := NVL(iv_out_rep_type, '0');  -- �o�͒��[�`��
    lr_param_rec.browser       := iv_browser;                 -- �{����
-- 2019/09/11 Ver1.8 Add End
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_info
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
    -- =====================================================
    -- �O����
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
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_vender>' ) ;
-- 2019/09/11 Ver1.8 Add Start
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <p_rep_type><![CDATA[2]]></p_rep_type>' ) ;
-- 2019/09/11 Ver1.8 Add End
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_vender>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : �Y�ؔN��
     ,iv_dept_code          IN     VARCHAR2         --   02 : �����Ǘ�����
     ,iv_vendor_code        IN     VARCHAR2         --   03 : �����
-- 2019/09/11 Ver1.8 Add Start
     ,iv_item_class         IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_out_file_type      IN     VARCHAR2         --   05 : �o�̓t�@�C���`��(������:0,PDF:1,CSV:2)
     ,iv_out_rep_type       IN     VARCHAR2         --   06 : �o�͒��[�`��(������:0,��:1,����:2)
     ,iv_browser            IN     VARCHAR2         --   07 : �{����(�ɓ���:1,�����:2)
-- 2019/09/11 Ver1.8 Add End
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
    submain
      (
        iv_fiscal_ym      => iv_fiscal_ym       --   01 : �Y�ؔN��
       ,iv_dept_code      => iv_dept_code       --   02 : �����Ǘ�����
       ,iv_vendor_code    => iv_vendor_code     --   03 : �����
-- 2019/09/11 Ver1.8 Add Start
       ,iv_item_class     => iv_item_class      --   04 : �i�ڋ敪
       ,iv_out_file_type  => iv_out_file_type   --   05 : �o�̓t�@�C���`��
       ,iv_out_rep_type   => iv_out_rep_type    --   06 : �o�͒��[�`��
       ,iv_browser        => iv_browser         --   07 : �{����
-- 2019/09/11 Ver1.8 Add End
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxpo780001c ;
/