create or replace PACKAGE BODY xxcmn770009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770009C(body)
 * Description      : ������U�֌������ٕ\
 * MD.050/070       : �����Y�؏������[Issue1.0(T_MD050_BPO_770)
 *                  : �����Y�؏������[Issue1.0(T_MD070_BPO_77I)
 * Version          : 1.17
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml               FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_set_xml                FUNCTION  : �w�l�k�p�z��Ɋi�[����B
 *  prc_initialize             PROCEDURE : �O����
 *  prc_get_report_data        PROCEDURE : ���׃f�[�^�擾(I-1)
 *  prc_create_xml_data        PROCEDURE : �w�l�k�f�[�^�쐬(I-2)
 *  submain                    PROCEDURE : ���C�������v���V�[�W��
 *  main                       PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  DATE          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/19    1.0   M.Hamamoto       �V�K�쐬
 *  2008/05/16    1.1   M.Hamamoto       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[�ɂȂ�
 *                                       �_���C���B
 *                                       ���[�ɏo�͂���Ă���̂́A�p�����[�^�̏����N���݂̂�
 *                                       ���̓p�����[�^��200804�ł͂Ȃ��A20084�Ƃ���Ɛ���ɒ��o
 *                                       ����邪�A�w�b�_�̏����N�������[�o�͎��ɏ����fYYYY/MM
 *                                       �f�֕ϊ������悤�C���B
 *  2008/05/31    1.2   M.Hamamoto       �����擾���@���C���B
 *  2008/06/19    1.3   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.4   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.5   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *  2008/08/07    1.6   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma09_v�v
 *  2008/08/27    1.7   A.Shiina         T_TE080_BPO_770 �w�E18�Ή�
 *  2008/10/14    1.8   N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/10/28    1.9   T.Ohashi         T_S_524�Ή�(PT�Ή�)�đΉ�
 *  2008/10/29    1.10  T.Ohashi         T_S_524�Ή�(PT�Ή�)�đΉ�
 *  2008/11/13    1.11  A.Shiina         �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.12  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#213�A214�Ή�
 *  2008/12/08    1.14  N.Yoshida        �{�ԏ�Q�Ή� �󒍃w�b�_�A�h�I���ōŐV�t���OY��ǉ�
 *  2008/12/18    1.15  A.Shiina         �{��#789�Ή�
 *  2009/01/14    1.16  N.Yoshida        �{��#1015�Ή�
 *  2009/05/12    1.17  M.Nomura         �{��#1469�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� start   #######################
--
  gv_status_normal        CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn          CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error         CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part             CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont             CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� start   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770009c' ;   -- �p�b�P�[�W��
--
-- 2008/11/14 v1.11 ADD START
  gc_rcv_pay_div_adj      CONSTANT VARCHAR2(2) := '-1' ;  --����
--
-- 2008/11/14 v1.11 ADD END
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code        CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag          CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_new_acnt_div         CONSTANT VARCHAR2(21)  := 'XXCMN_NEW_ACCOUNT_DIV';
--
  ------------------------------
  -- �S�p����
  ------------------------------
  gc_cat_prod_div         CONSTANT VARCHAR2(8)   := '���i�敪' ;
  gc_cat_item_div         CONSTANT VARCHAR2(8)   := '�i�ڋ敪' ;
  gc_cap_from             CONSTANT VARCHAR2(14)  := '�����N��(FROM)' ;
  gc_cap_to               CONSTANT VARCHAR2(12)  := '�����N��(TO)' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- �A�v���P�[�V�����ixxcmn�j
  gc_param_name           CONSTANT VARCHAR2(10) := 'PARAM_NAME' ;
  gc_param_value          CONSTANT VARCHAR2(11) := 'PARAM_VALUE';
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�Bview' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '���[�U�[id' ;
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '�N' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '��' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '��' ;
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_y                   CONSTANT VARCHAR2(1) := 'Y' ;
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  gn_one                 CONSTANT NUMBER        := 1   ;
  gn_two                 CONSTANT NUMBER        := 2   ;
  gn_one1                CONSTANT NUMBER        := '1' ;
  gc_gun                 CONSTANT VARCHAR2(1) := '3' ;
  gc_sla                 CONSTANT VARCHAR2(1) := '/' ;
  gc_sla_zero_one        CONSTANT VARCHAR2(3) := '/01' ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD(
      proc_from            VARCHAR2(6)   -- �����N��FROM
-- 2008/12/18 v1.15 UPDATE START
--     ,proc_from_date_ch    VARCHAR2(10)  -- �����N��FROM(���t������)
     ,proc_from_date_ch    VARCHAR2(20)  -- �����N��FROM(�����b������)
-- 2008/12/18 v1.15 UPDATE END
     ,proc_from_date       DATE          -- �����N��FROM(���t) - 1(�挎�̖���)
     ,proc_to              VARCHAR2(6)   -- �����N��to
-- 2008/12/18 v1.15 UPDATE START
--     ,proc_to_date_ch      VARCHAR2(10)  -- �����N��to(���t������)
     ,proc_to_date_ch      VARCHAR2(20)  -- �����N��to(�����b������)
-- 2008/12/18 v1.15 UPDATE END
     ,proc_to_date         DATE          -- �����N��to(���t) - 1(������1��)
     ,prod_div             VARCHAR2(10)  -- ���i�敪
     ,item_div             VARCHAR2(10)  -- �i�ڋ敪
     ,rcv_pay_div          VARCHAR2(10)  -- �󕥋敪
     ,crowd_type           VARCHAR2(10)  -- �W�v���
     ,crowd_code           VARCHAR2(10)  -- �Q�R�[�h
     ,acnt_crowd_code      VARCHAR2(10)  -- �o���Q�R�[�h
    ) ;
--
    gr_param          rec_param_data ;          -- �p�����[�^��n���p
--
  --�w�b�_�p
  TYPE rec_header  IS RECORD(
      report_id           VARCHAR2(12)     -- ���[id
     ,exec_date           DATE             -- ���{��
     ,proc_from_char      VARCHAR2(10)                                 --�����N��FROM(yyyy�Nmm��)
     ,proc_to_char        VARCHAR2(10)                                 --�����N��to  (yyyy�Nmm��)
     ,user_id             xxpo_per_all_people_f_v.person_id%TYPE       --�S����id
     ,user_name           per_all_people_f.per_information18%TYPE      --�S����
     ,user_dept           xxcmn_locations_all.location_short_name%TYPE --����
    ) ;
--
  gr_header           rec_header;
--
  -- �d��������ו\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
     item_code_from xxcmn_lot_each_item_v.item_code%TYPE
    ,item_name_from xxcmn_lot_each_item_v.item_short_name%TYPE
    ,item_code_to xxcmn_rcv_pay_mst_porc_rma_v.request_item_code%TYPE
    ,item_name_to xxcmn_item_mst2_v.item_short_name%TYPE
    ,gun_code xxcmn_lot_each_item_v.crowd_code%TYPE
    ,rcv_pay_div xxcmn_rcv_pay_mst_porc_rma_v.rcv_pay_div%TYPE
    ,trans_qty   NUMBER
    ,from_price  NUMBER
    ,from_cost   NUMBER
    ,to_price    NUMBER
    ,to_cost     NUMBER
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  --�L�[���ꔻ�f�p
  TYPE rec_keybreak  IS RECORD(
       prod_div       VARCHAR2(200)  --���i�敪
     , item_div       VARCHAR2(200)  --�i�ڋ敪
     , rcv_pay_div    VARCHAR2(200)  --�󕥋敪
     , crowd_high     VARCHAR2(200)  --��Q
     , crowd_mid      VARCHAR2(200)  --���Q
     , crowd_low      VARCHAR2(200)  --���Q
     , crowd_dtl      VARCHAR2(200)  --�ڌQ
     , item_from      VARCHAR2(200)  --�U�֌��i��
     , item_to        VARCHAR2(200)  --�U�֐�i��
    ) ;
--
  gr_rec tab_data_type_dtl;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �����������p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;  -- �c�ƒP��
--
  ------------------------------
  -- �������p
  ------------------------------
  gt_xml_data_table         xml_data ;                -- �������f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �������f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
--
--#####################  �Œ苤�ʗ�O�錾�� start   ####################
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
   /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �������^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� start   ########################
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
-- 2008/12/18 v1.15 ADD START
    -- *** ���[�J���萔 ***
    lc_f_time          CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time          CONSTANT VARCHAR2(10) := ' 23:59:59';
--
-- 2008/12/18 v1.15 ADD END
    -- *** ���[�J���ϐ� ***
    lv_f_date      VARCHAR2(20);
    lv_e_date      VARCHAR2(20);
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ���[�o�͒l�i�[
    gr_header.report_id                   := 'XXCMN770009T' ;     -- ���[id
    gr_header.exec_date                   := SYSDATE        ;     -- ���{��
--
    -- ====================================================
    -- �Ώ۔N��
    -- ====================================================
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_from , gc_char_y_format),gc_char_y_format);
    --���t�^�ݒ�
    gr_param.proc_from_date_ch := SUBSTR(gr_param.proc_from,1,4) || gc_sla
-- 2008/12/18 v1.15 UPDATE START
--                               || SUBSTR(gr_param.proc_from,5,2) || gc_sla_zero_one;
                               || SUBSTR(gr_param.proc_from,5,2) || gc_sla_zero_one || lc_f_time;
-- 2008/12/18 v1.15 UPDATE END
    gr_param.proc_from_date    :=  FND_DATE.STRING_TO_DATE( gr_param.proc_from_date_ch
-- 2008/12/18 v1.15 UPDATE START
--                                                          , gc_char_d_format) - 1;
                                                          , gc_char_dt_format);
-- 2008/12/18 v1.15 UPDATE END
--
    -- ���t�ϊ�
    gr_header.proc_from_char := SUBSTR(lv_f_date,1,4) || gc_jp_yy
                             || SUBSTR(lv_f_date,5,2) || gc_jp_mm;
    IF (gr_param.proc_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                           , 'APP-XXCMN-10035'
                                           , gc_param_name
                                           , gc_cap_from
                                           , gc_param_value
                                           , gr_param.proc_from ) ;
      RAISE get_value_expt ;
    END IF;
--
    lv_e_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_to , gc_char_y_format),gc_char_y_format);
--
    gr_param.proc_to_date_ch   := SUBSTR(gr_param.proc_to,1,4) || gc_sla
                               || SUBSTR(gr_param.proc_to,5,2) || gc_sla_zero_one;
-- 2008/12/18 v1.15 UPDATE START
--    gr_param.proc_to_date      := ADD_MONTHS(FND_DATE.STRING_TO_DATE( gr_param.proc_to_date_ch
--                                                         , gc_char_d_format), 1);
    gr_param.proc_to_date      := LAST_DAY(FND_DATE.STRING_TO_DATE( gr_param.proc_to_date_ch
                                                         , gc_char_d_format));
-- 2008/12/18 v1.15 UPDATE END
    -- ���t�ϊ�
    gr_header.proc_to_char   := SUBSTR(lv_e_date,1,4)   || gc_jp_yy
                             || SUBSTR(lv_e_date,5,2)   || gc_jp_mm;
    IF (gr_param.proc_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              , 'APP-XXCMN-10035'
                                              , gc_param_name
                                              , gc_cap_to
                                              , gc_param_value
                                              , gr_param.proc_to ) ;
      RAISE get_value_expt ;
    END IF;
-- 2008/12/18 v1.15 UPDATE START
--    gr_param.proc_to_date_ch   := TO_CHAR(gr_param.proc_to_date,gc_char_d_format);
    gr_param.proc_to_date_ch   := TO_CHAR(gr_param.proc_to_date,gc_char_d_format) || lc_e_time;
-- 2008/12/18 v1.15 UPDATE END
--
    -- ====================================================
    -- �S�������E�S���Җ�
    -- ====================================================
    BEGIN
      gr_header.user_id   := FND_GLOBAL.USER_ID;
      gr_header.user_dept := xxcmn_common_pkg.get_user_dept(gr_header.user_id);
      gr_header.user_name := xxcmn_common_pkg.get_user_name(gr_header.user_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL ;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ start   ####################################
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(I-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_data_rec   OUT nocopy tab_data_type_dtl  -- 02.�擾���R�[�h�Q
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
--#####################  �Œ胍�[�J���ϐ��錾�� start   ########################
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
    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';
    cv_lang           CONSTANT VARCHAR2(2)  := 'JA';
    cv_lookup         CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cn_one            CONSTANT NUMBER       := 1;
    -- �����^�C�v
    cv_porc           CONSTANT VARCHAR2(4)  := 'PORC';
    cv_omso           CONSTANT VARCHAR2(4)  := 'OMSO';
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_code_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
--
    -- *** ���[�J���E�ϐ� ***
    lv_date_from  VARCHAR2(10) ;
    lv_date_to    VARCHAR2(10) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p������
-- 2008/11/14 v1.11 ADD START
    ln_crowd_code_id NUMBER;
    lt_crowd_code    mtl_categories_b.segment1%TYPE;
-- 2008/11/14 v1.11 ADD END
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/14 v1.8 ADD START
    -- ----------------------------------------------------
    -- ���̓p�����[�^�ɂ��J�[�\���̑I�����s��
    -- ----------------------------------------------------
    --===============================================================
    -- ��������.�󕥋敪          �� ���͂Ȃ�
    -- ��������.�Q���            �� �Q��/�o���S��
    -- ��������.�Q�R�[�h          �� ���͂Ȃ�
    -- ��������.�o���Q�R�[�h      �� ���͂Ȃ�/���͂���
    --===============================================================
    CURSOR get_cur01 IS
      -- ----------------------------------------------------
      -- PORC1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '104'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
--      AND    xoha.req_status         IN ('04','08')
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
--      AND    otta.attribute1         IN ('1','2')
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '107'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '104'
      AND    xrpm.shipment_provision_div = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '107'
      AND    xrpm.shipment_provision_div  = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    mcb4.segment1           = '1'
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
      AND    mcb5.segment1           = '5'
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      ORDER BY rcv_pay_div
              ,gun_code
              ,item_code_to
              ,item_code_from
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� ���͂���
    -- ��������.�Q���            �� �Q��/�o���S��
    -- ��������.�Q�R�[�h          �� ���͂Ȃ�
    -- ��������.�o���Q�R�[�h      �� ���͂Ȃ�/���͂���
    --===============================================================
    CURSOR get_cur02 IS
      -- ----------------------------------------------------
      -- PORC1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '104'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
--      AND    xoha.req_status         IN ('04','08')
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
--      AND    otta.attribute1         IN ('1','2')
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '107'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '104'
      AND    xrpm.shipment_provision_div = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '107'
      AND    xrpm.shipment_provision_div  = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    mcb4.segment1           = '1'
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
      AND    mcb5.segment1           = '5'
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      ORDER BY rcv_pay_div
              ,gun_code
              ,item_code_to
              ,item_code_from
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� ���͂Ȃ�
    -- ��������.�Q���            �� �Q��/�o���S��
    -- ��������.�Q�R�[�h          �� ���͂���
    -- ��������.�o���Q�R�[�h      �� ���͂Ȃ�/���͂���
    --===============================================================
    CURSOR get_cur03 IS
      -- ----------------------------------------------------
      -- PORC1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '104'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
--      AND    xoha.req_status         IN ('04','08')
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
--      AND    otta.attribute1         IN ('1','2')
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '107'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '104'
      AND    xrpm.shipment_provision_div = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '107'
      AND    xrpm.shipment_provision_div  = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    mcb4.segment1           = '1'
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
      AND    mcb5.segment1           = '5'
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      ORDER BY rcv_pay_div
              ,gun_code
              ,item_code_to
              ,item_code_from
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� ���͂���
    -- ��������.�Q���            �� �Q��/�o���S��
    -- ��������.�Q�R�[�h          �� ���͂���
    -- ��������.�o���Q�R�[�h      �� ���͂Ȃ�/���͂���
    --===============================================================
    CURSOR get_cur04 IS
      -- ----------------------------------------------------
      -- PORC1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '104'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
--      AND    xoha.req_status         IN ('04','08')
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
--      AND    otta.attribute1         IN ('1','2')
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) use_nl (xoha ooha otta xola iimb gic2 mcb2 gic1 mcb1 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '107'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- PORC6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO1 :�o���󕥋敪�w���֘A (�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           <> '5'
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '104'
      AND    xrpm.shipment_provision_div = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO2 :�o���󕥋敪�w���֘A (�U�֗L��_���o)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO3 :�o���󕥋敪�w���֘A (���i�U�֗L��_���)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_ahead     = mcb1.segment1
      AND    xrpm.prod_div_ahead     = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    xrpm.prod_div_origin    = mcb4.segment1
      AND    gic5.item_id            = itp.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    gic5.category_id        = mcb5.category_id
      AND    xrpm.item_div_origin    = mcb5.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '107'
      AND    xrpm.shipment_provision_div  = '2'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO4 :�o���󕥋敪�w���֘A (���i�U�֗L��_���o)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,gmi_item_categories              gic5
            ,mtl_categories_b                 mcb5
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
--      AND    xrpm.prod_div_origin    = mcb1.segment1
      AND    xrpm.prod_div_origin    = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_origin    = mcb2.segment1
      AND    xrpm.item_div_origin    = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '109'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.shipment_provision_div = '2'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xola.request_item_code  = iimb2.item_no
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    mcb4.category_id        = gic4.category_id
      AND    mcb4.segment1           = '1'
      AND    gic5.item_id            = iimb2.item_id
      AND    gic5.category_set_id    = cn_item_class_id
      AND    mcb5.category_id        = gic5.category_id
      AND    mcb5.segment1           = '5'
--      AND    xrpm.prod_div_ahead     = mcb4.segment1
--      AND    xrpm.item_div_ahead     = mcb5.segment1
      AND    xrpm.prod_div_ahead     = '1'
      AND    xrpm.item_div_ahead     = '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO5 :�o���󕥋敪�w���֘A (���_���A���_��)
      -- ----------------------------------------------------
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */
      SELECT /*+ leading (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
--      AND    xrpm.item_div_ahead     = mcb2.segment1
      AND    xrpm.item_div_ahead     = gr_param.item_div
      AND    gic3.item_id            = iimb.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = itp.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           IN ('1','4')
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb4.segment1
-- 2008/11/19 v1.12 ADD END
--      AND    xrpm.item_div_origin    = mcb4.segment1
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_09       IS NOT NULL
      AND    itp.item_id             = iimb2.item_id
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      UNION ALL
      -- ----------------------------------------------------
      -- OMSO6 :�o���󕥋敪�w���֘A (�U�֏o��)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iimb2.item_no               item_code_from
            ,ximb2.item_short_name       item_name_from
            ,iimb.item_no                item_code_to
            ,ximb.item_short_name        item_name_to
            ,mcb3.segment1               gun_code
            ,xrpm.new_div_account        rcv_pay_div
            ,SUM(itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,SUM(
-- 2008/11/29 v1.13 UPDATE START
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))) AS from_price
            ,SUM(ROUND(
--               DECODE(iimb.attribute15
               DECODE(iimb2.attribute15
                    ,gn_one,NVL(xsup_m.stnd_unit_price,0)
--                    ,DECODE(iimb.lot_ctl
                    ,DECODE(iimb2.lot_ctl
-- 2008/11/29 v1.13 UPDATE END
                      ,gn_one1,xlc.unit_ploce,NVL(xsup_m.stnd_unit_price,0)))
               * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) AS from_cost
-- 2008/11/29 v1.13 UPDATE START
--            ,SUM(xsup.stnd_unit_price) to_price
--            ,SUM(ROUND(xsup.stnd_unit_price
            ,SUM(xsup.stnd_unit_price_gen) to_price
            ,SUM(ROUND(xsup.stnd_unit_price_gen
-- 2008/11/29 v1.13 UPDATE END
              * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))) to_cost
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,xxcmn_item_mst_b                 ximb2
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- %%%%%%%%%% 2009/5/12 v1.17 S %%%%%%%%%%
--            ,xxcmn_stnd_unit_price_v          xsup_m
--            ,xxcmn_stnd_unit_price_v          xsup
            ,xxcmn_stnd_unit_price2_v          xsup_m
            ,xxcmn_stnd_unit_price2_v          xsup
-- %%%%%%%%%% 2009/5/12 v1.17 E %%%%%%%%%%
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = 1
-- 2008/12/18 v1.15 UPDATE START
--      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_d_format)
--      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_d_format)
      AND  xoha.arrival_date >= FND_DATE.STRING_TO_DATE(gr_param.proc_from_date_ch,gc_char_dt_format)
      AND  xoha.arrival_date <= FND_DATE.STRING_TO_DATE(gr_param.proc_to_date_ch,gc_char_dt_format)
-- 2008/12/18 v1.15 UPDATE END
-- ADD START 1.14
      AND  xoha.latest_external_flag = 'Y'
-- ADD END 1.14
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = gr_param.prod_div
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = gr_param.item_div
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_09       IS NOT NULL
      AND    iimb2.item_id           = ximb2.item_id
-- 2009/01/14 v1.16 N.Yoshida mod start
--      AND    xsup_m.item_id          = iimb2.item_id
--      AND    itp.trans_date BETWEEN xsup_m.start_date_active AND xsup_m.end_date_active
      AND    xsup_m.item_id(+)       = iimb2.item_id
      AND    NVL(xsup_m.start_date_active, itp.trans_date) <= itp.trans_date
      AND    NVL(xsup_m.end_date_active, itp.trans_date)   >= itp.trans_date
-- 2009/01/14 v1.16 N.Yoshida mod start
      AND    xsup.item_id            = iimb.item_id
      AND    itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active
      AND    mcb3.segment1           = lt_crowd_code
      AND    xrpm.new_div_account    = gr_param.rcv_pay_div
      GROUP BY iimb2.item_no
              ,ximb2.item_short_name
              ,iimb.item_no
              ,ximb.item_short_name
              ,mcb3.segment1
              ,xrpm.new_div_account
      ORDER BY rcv_pay_div
              ,gun_code
              ,item_code_to
              ,item_code_from
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    lv_date_from := TO_CHAR(gr_param.proc_from_date , gc_char_d_format);
    lv_date_to   := TO_CHAR(gr_param.proc_to_date   , gc_char_d_format);
--
    -- ====================================================
    -- ����������
    -- ====================================================
--
-- 2008/10/14 v1.8 DELETE START
    /*lv_sql := 'SELECT '
      || '  xlei.item_code item_code_from,         '     --�i�ڃR�[�h
      || '  xlei.item_short_name item_name_from,   '     --�i�ږ���
      || '  xrpmpr.request_item_code item_code_to, '     --���i�󕥕i�ڃR�[�h
      || '  ximv.item_short_name item_name_to,     '     --���i�󕥕i�ږ���
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code                 gun_code ,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code            gun_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmpr.new_div_account rcv_pay_div,                    ' --����敪
-- 2008/08/27 v1.7 UPDATE START
--      || '  SUM(itp.trans_qty) trans_qty,                          ' --����
      || '  SUM(itp.trans_qty * TO_NUMBER(xrpmpr.rcv_pay_div)) trans_qty, ' --����
-- 2008/08/27 v1.7 UPDATE END
      || '  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      || '    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      || '    xsup_m.stnd_unit_price)) '
      || '       )                      AS from_price ,'         --���ےP��
      || '  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      || '    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
-- 2008/08/27 v1.7 UPDATE START
--      || '    xsup_m.stnd_unit_price)) * itp.trans_qty '
      || '    xsup_m.stnd_unit_price)) * (itp.trans_qty * TO_NUMBER(xrpmpr.rcv_pay_div)) '
-- 2008/08/27 v1.7 UPDATE END
      || '     )    AS from_cost ,'     --���ی���
      || '  SUM(xsup.stnd_unit_price_gen) to_price,                ' --������
-- 2008/08/27 v1.7 UPDATE START
--      || '  SUM(xsup.stnd_unit_price_gen * itp.trans_qty)  to_cost ' --�U�֐�W���������z
      --�U�֐�W���������z
      || ' SUM(xsup.stnd_unit_price_gen * (itp.trans_qty * TO_NUMBER(xrpmpr.rcv_pay_div))) to_cost '
-- 2008/08/27 v1.7 UPDATE END
      || 'FROM xxcmn_rcv_pay_mst_porc_rma09_v xrpmpr '   --�o���󕥋敪���view_�w���֘A
      || '   , ic_tran_pnd              itp'           --�݌Ƀg����
      || '   , xxcmn_lot_each_item_v    xlei '
      || '   , xxcmn_stnd_unit_price_v  xsup '
      || '   , xxcmn_stnd_unit_price_v  xsup_m '
      || '   , xxcmn_item_mst2_v        ximv '
      || '   , xxcmn_item_categories6_v xicv '
      || '   , xxcmn_lookup_values2_v   xlvv '
      || 'WHERE itp.doc_type            = ''' || cv_porc || ''''
      || '  AND itp.completed_ind       = '   || TO_CHAR(cn_one)
      || '  AND itp.trans_date BETWEEN xlei.start_date_active AND xlei.end_date_active'
      || '  AND xrpmpr.doc_type         = itp.doc_type'
      || '  AND xrpmpr.doc_id           = itp.doc_id'
      || '  AND xrpmpr.doc_line         = itp.doc_line'
      || '  AND xlei.item_id            = itp.item_id'
      || '  AND xlei.lot_id             = itp.lot_id'
      || '  AND xlei.item_id             = xsup_m.item_id'
      || '  AND xrpmpr.request_item_code = ximv.item_no(+)'
      || '  AND ximv.item_id            = xicv.item_id'
      || '  AND xsup.item_id            = ximv.item_id'
      || '  AND itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active'
      || '  AND xlvv.lookup_type        = ''' || cv_lookup || ''''
      || '  AND xrpmpr.dealings_div     = xlvv.meaning'
      || '  AND (xlvv.start_date_active IS NULL OR xlvv.start_date_active '
      ||                                               ' <= TRUNC(itp.trans_date))'
      || '  AND (xlvv.end_date_active   IS NULL OR xlvv.end_date_active '
      ||                                               ' >= TRUNC(itp.trans_date))'
      || '  AND xlvv.language           = ''' || cv_lang || ''''
      || '  AND xlvv.source_lang        = ''' || cv_lang || ''''
      || '  AND xlvv.enabled_flag       = ''' || cv_yes || ''''
      || '  AND xlvv.attribute9         IS NOT NULL   '-- ���[�t���O
      || '  AND itp.trans_date          >= FND_DATE.STRING_TO_DATE('
      ||                                   ''''|| gr_param.proc_from_date_ch || ''''
      ||                                   ','''|| gc_char_d_format || ''')'
      || '  AND itp.trans_date          <  FND_DATE.STRING_TO_DATE('
      ||                                   ''''|| gr_param.proc_to_date_ch || ''''
      ||                                   ','''|| gc_char_d_format || ''')'
      || '  AND xicv.prod_class_code    = ''' || gr_param.prod_div || ''''
      || '  AND xicv.item_class_code    = ''' || gr_param.item_div || ''''
      ;
    IF (gr_param.rcv_pay_div IS NOT NULL) THEN
      lv_sql := lv_sql
        || '  AND xrpmpr.new_div_account  = ''' || gr_param.rcv_pay_div || '''';
    END IF
    ;
    IF (gr_param.crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.crowd_code   = ''' || gr_param.crowd_code || '''';
    END IF
    ;
    IF (gr_param.acnt_crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.acnt_crowd_code   = ''' || gr_param.acnt_crowd_code || '''';
    END IF
    ;
    lv_sql := lv_sql
      || 'GROUP BY '
      || '  xlei.item_code, '          -- �i�ڃR�[�h
      || '  xlei.item_short_name,'     -- �i�ږ���
      || '  xrpmpr.request_item_code,' -- ���i�󕥕i�ڃR�[�h
      || '  ximv.item_short_name,    ' -- ���i�󕥕i�ږ���
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code ,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmpr.new_div_account                            ' -- ����敪
      || 'UNION ALL '
      || 'SELECT '
      || '  xlei.item_code          item_code_from,           ' -- �i�ڃR�[�h
      || '  xlei.item_short_name    item_name_from,           ' -- �i�ږ���
      || '  xrpmo.request_item_code item_code_to,             ' -- ���i�󕥕i�ڃR�[�h
      || '  ximv.item_short_name    item_name_to,             ' -- ���i�󕥕i�ږ���
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code      gun_code,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code gun_code,';
    END IF
    ;
    lv_sql := lv_sql
      ||'  xrpmo.new_div_account rcv_pay_div,                         ' -- ����敪
-- 2008/08/27 v1.7 UPDATE START
--      ||'  SUM(itp.trans_qty) trans_qty,                          ' -- ����
      ||'  SUM(itp.trans_qty * TO_NUMBER(xrpmo.rcv_pay_div)) trans_qty,  ' -- ����
-- 2008/08/27 v1.7 UPDATE END
      ||'  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      ||'    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      ||'    xsup_m.stnd_unit_price)) '
      ||'       )                       AS from_price ,'                --���ےP��
      ||'  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      ||'  DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
-- 2008/08/27 v1.7 UPDATE START
--      ||'  xsup_m.stnd_unit_price)) * itp.trans_qty '
      ||'  xsup_m.stnd_unit_price)) * (itp.trans_qty * TO_NUMBER(xrpmo.rcv_pay_div)) '
-- 2008/08/27 v1.7 UPDATE END
      ||'  )    AS from_cost ,'    --���ی���
      ||'  SUM(xsup.stnd_unit_price_gen) to_price,                ' -- ������
-- 2008/08/27 v1.7 UPDATE START
--      ||'  SUM(xsup.stnd_unit_price_gen * itp.trans_qty)  to_cost ' -- �U�֐�W���������z
      -- �U�֐�W���������z
      ||'  SUM(xsup.stnd_unit_price_gen * (itp.trans_qty * TO_NUMBER(xrpmo.rcv_pay_div))) to_cost '
-- 2008/08/27 v1.7 UPDATE END
      ||'FROM xxcmn_rcv_pay_mst_omso_v xrpmo '                     -- �o���󕥋敪���view_�󒍊֘A
      ||'   , ic_tran_pnd              itp  '   --�݌Ƀg����
      ||'   , xxcmn_lot_each_item_v    xlei '
      ||'   , xxcmn_stnd_unit_price_v  xsup '    --�W���������view
      || '   , xxcmn_stnd_unit_price_v  xsup_m '
      ||'   , xxcmn_lookup_values2_v   xlvv '
      ||'   , xxcmn_item_mst2_v        ximv '
      ||'   , xxcmn_item_categories6_v xicv '
      ||'WHERE itp.doc_type            = ''' || cv_omso || ''''
      ||'  AND itp.completed_ind       = '   || TO_CHAR(cn_one)
      ||'  AND xrpmo.doc_type          = itp.doc_type'
      ||'  AND xrpmo.doc_line          = itp.line_detail_id'
      ||'  AND xlei.item_id            = itp.item_id'
      ||'  AND xlei.lot_id             = itp.lot_id'
      || ' AND xlei.item_id             = xsup_m.item_id'
      ||'  AND itp.trans_date BETWEEN xlei.start_date_active AND xlei.end_date_active'
      ||'  AND xsup.item_id            = ximv.item_id'
      ||'  AND itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active'
      ||'  AND xrpmo.request_item_code = ximv.item_no(+)'
      ||'  AND ximv.item_id            = xicv.item_id'
      ||'  AND xlvv.lookup_type        = ''' || cv_lookup || ''''
      ||'  AND xrpmo.dealings_div      = xlvv.meaning'
      ||'  AND (xlvv.start_date_active IS NULL OR xlvv.start_date_active  <= TRUNC(itp.trans_date))'
      ||'  AND (xlvv.end_date_active   IS NULL OR xlvv.end_date_active    >= TRUNC(itp.trans_date))'
      ||'  AND xlvv.language           = ''' || cv_lang || ''''
      ||'  AND xlvv.source_lang        = ''' || cv_lang || ''''
      ||'  AND xlvv.enabled_flag       = ''' || cv_yes || ''''
      ||'  AND xlvv.attribute9         IS NOT NULL   ' -- ���[�t���O
      ||'  AND itp.trans_date          >= FND_DATE.STRING_TO_DATE('
      ||                                  ''''|| gr_param.proc_from_date_ch || ''''
      ||                                  ','''|| gc_char_d_format || ''')'
      ||'  AND itp.trans_date          <  FND_DATE.STRING_TO_DATE('
      ||                                  ''''|| gr_param.proc_to_date_ch || ''''
      ||                                  ','''|| gc_char_d_format || ''')'
      ||'  AND xicv.prod_class_code    = ''' || gr_param.prod_div || ''''
      ||'  AND xicv.item_class_code    = ''' || gr_param.item_div || ''''
      ;
    IF (gr_param.rcv_pay_div IS NOT NULL) THEN
      lv_sql := lv_sql
        || '  AND xrpmo.new_div_account  = ''' || gr_param.rcv_pay_div || '''';
    END IF
    ;
    IF (gr_param.crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.crowd_code   = ''' || gr_param.crowd_code || '''';
    END IF
    ;
    IF (gr_param.acnt_crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.acnt_crowd_code   = ''' || gr_param.acnt_crowd_code || '''';
    END IF
    ;
    lv_sql := lv_sql
      ||'GROUP BY  xlei.item_code , '           --�i�ڃR�[�h
      ||'          xlei.item_short_name , '     --�i�ږ���
      ||'          xrpmo.request_item_code ,  ' --���i�󕥕i�ڃR�[�h
      ||'          ximv.item_short_name,'       --���i�󕥕i�ږ���
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmo.new_div_account ' --����敪
    ;
    lv_sql := lv_sql
      || 'ORDER BY  rcv_pay_div '
      ||         ', gun_code '
      ||         ', item_code_to '
      ||         ', item_code_from '
    ;
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;*/
-- 2008/10/14 v1.8 DELETE END
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
--
-- 2008/10/14 v1.8 ADD START
    -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
    IF  (gr_param.crowd_type = gc_gun) THEN
--
-- 2008/11/14 v1.11 ADD START
--
          ln_crowd_code_id := cn_crowd_code_id;
          lt_crowd_code    := gr_param.crowd_code;
--
-- 2008/11/14 v1.11 ADD END
      -- �󕥋敪�����͂���Ă���ꍇ
      IF (gr_param.rcv_pay_div IS NOT NULL) THEN
--
        -- �Q�R�[�h�����͂���Ă���ꍇ
        IF (gr_param.crowd_code IS NOT NULL) THEN
          OPEN  get_cur04;
          FETCH get_cur04 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur04;
--
        -- �Q�R�[�h�����͂���Ă��Ȃ��ꍇ
        ELSE
          OPEN  get_cur02;
          FETCH get_cur02 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur02;
--
        END IF;
--
      ELSE
--
        -- �Q�R�[�h�����͂���Ă���ꍇ
        IF (gr_param.crowd_code IS NOT NULL) THEN
          OPEN  get_cur03;
          FETCH get_cur03 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur03;
--
        -- �Q�R�[�h�����͂���Ă��Ȃ��ꍇ
        ELSE
          OPEN  get_cur01;
          FETCH get_cur01 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur01;
--
        END IF;
--
      END IF;
--
    -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
    ELSE
--
-- 2008/11/14 v1.11 ADD START
--
          ln_crowd_code_id := cn_acnt_crowd_code_id;
          lt_crowd_code    := gr_param.acnt_crowd_code;
--
-- 2008/11/14 v1.11 ADD END

      -- �󕥋敪�����͂���Ă���ꍇ
      IF (gr_param.rcv_pay_div IS NOT NULL) THEN
--
        -- �o���Q�R�[�h�����͂���Ă���ꍇ
        IF (gr_param.crowd_code IS NOT NULL) THEN
-- 2008/11/14 v1.11 UPDATE START
--          OPEN  get_cur08;
--          FETCH get_cur08 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_cur08;
          OPEN  get_cur04;
          FETCH get_cur04 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur04;
-- 2008/11/14 v1.11 UPDATE END
--
        -- �o���Q�R�[�h�����͂���Ă��Ȃ��ꍇ
        ELSE
-- 2008/11/14 v1.11 UPDATE START
--          OPEN  get_cur06;
--          FETCH get_cur06 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_cur06;
          OPEN  get_cur02;
          FETCH get_cur02 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur02;
-- 2008/11/14 v1.11 UPDATE END
--
        END IF;
--
      ELSE
--
        -- �o���Q�R�[�h�����͂���Ă���ꍇ
        IF (gr_param.crowd_code IS NOT NULL) THEN
-- 2008/11/14 v1.11 UPDATE START
--          OPEN  get_cur07;
--          FETCH get_cur07 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_cur07;
          OPEN  get_cur03;
          FETCH get_cur03 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur03;
-- 2008/11/14 v1.11 UPDATE END
--
        -- �o���Q�R�[�h�����͂���Ă��Ȃ��ꍇ
        ELSE
-- 2008/11/14 v1.11 UPDATE START
--          OPEN  get_cur05;
--          FETCH get_cur05 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_cur05;
          OPEN  get_cur01;
          FETCH get_cur01 BULK COLLECT INTO ot_data_rec;
          CLOSE get_cur01;
-- 2008/11/14 v1.11 UPDATE END
--
        END IF;
--
      END IF;
--
    END IF;
-- 2008/10/14 v1.8 ADD END
--
  EXCEPTION
--#################################  �Œ��O������ start   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �������f�[�^�쐬(I-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
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
--#####################  �Œ胍�[�J���ϐ��錾�� start   ########################
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
    lc_break                CONSTANT VARCHAR2(100) := '**' ;
--
    lc_depth_crowd_dtl      CONSTANT NUMBER :=  3;  -- �ڌQ
    lc_depth_crowd_low      CONSTANT NUMBER :=  5;  -- ���Q
    lc_depth_crowd_mid      CONSTANT NUMBER :=  7;  -- ���Q
    lc_depth_crowd_high     CONSTANT NUMBER :=  9;  -- ��Q
    lc_depth_rcv_pay_div    CONSTANT NUMBER := 11;  -- �󕥋敪
    lc_depth_item_div       CONSTANT NUMBER := 13;  -- �i�ڋ敪
    lc_depth_prod_div       CONSTANT NUMBER := 15;  -- ���i�敪
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- ���s�[�x(�J�n�^�O�o�͗p
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- ���z�v�Z�p
    ln_qty                  NUMBER DEFAULT 0;         -- �o����
    ln_to_price             NUMBER DEFAULT 0;         -- ��W������
    ln_to_gen               NUMBER DEFAULT 0;         -- ��W�����z
    ln_from_price           NUMBER DEFAULT 0;         -- �����ےP��
    ln_from_gen             NUMBER DEFAULT 0;         -- �����ۋ��z
    ln_sai_tan              NUMBER DEFAULT 0;         -- �P������
    ln_sai_gen              NUMBER DEFAULT 0;         -- ��������
    --�����v�p
    ln_sum_qty              NUMBER DEFAULT 0;         -- �o����
    ln_sum_to_price         NUMBER DEFAULT 0;         -- ��W������
    ln_sum_to_gen           NUMBER DEFAULT 0;         -- ��W�����z
    ln_sum_from_price       NUMBER DEFAULT 0;         -- �����ےP��
    ln_sum_from_gen         NUMBER DEFAULT 0;         -- �����ۋ��z
    ln_sum_sai_tan          NUMBER DEFAULT 0;         -- �P������
    ln_sum_sai_gen          NUMBER DEFAULT 0;         -- ��������
--
    lb_ret                  BOOLEAN;
    ln_loop_index           NUMBER DEFAULT 0;
    lv_prod_div_name        VARCHAR2(20);
    lv_rcv_pay_div_name     VARCHAR2(20);
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--
    ---------------------
    --  xml���ڃZ�b�g
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR    --  �^�O�^�C�v  T:�^�O
                                                            -- D:�f�[�^
                                                            -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                            -- Y:�f�[�^(NULL,0�̏ꍇ�^�O�������Ȃ�)
                                                            -- Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2                --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
      )
    IS
      ln_xml_idx NUMBER;
      ln_work    NUMBER;
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULL�̏ꍇ�^�O�������Ȃ��Ή�
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      ELSIF (ic_type = gc_y) THEN
        --NULL,0�̏ꍇ�^�O�������Ȃ��Ή�(���l���ڂ�z��)
        IF (NVL(iv_value, 0) = 0) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --NULL�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --NULL�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���i�敪���擾
    BEGIN
      SELECT SUBSTRB(xcat_prod.description, 1 ,20)
      INTO   lv_prod_div_name
      FROM   xxcmn_categories_v xcat_prod
      WHERE  xcat_prod.category_set_name = gc_cat_prod_div
        AND  xcat_prod.segment1          = gr_param.prod_div
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --�󕥋敪���擾
    IF (gr_param.rcv_pay_div IS NOT NULL)THEN
      BEGIN
        SELECT SUBSTRB(xlv_rcv_pay.meaning, 1 ,20)
        INTO   lv_rcv_pay_div_name
        FROM   xxcmn_lookup_values2_v xlv_rcv_pay
        WHERE  xlv_rcv_pay.lookup_type = gc_new_acnt_div
          AND  xlv_rcv_pay.lookup_code = gr_param.rcv_pay_div
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- =====================================================
    -- �w�b�_�[�f�[�^���o�E�o�͏���
    -- =====================================================
    -- �w�b�_�[�J�n�^�O
    prc_set_xml('T', 'user_info');
--
    -- ���[����
    prc_set_xml('D', 'report_id', gr_header.report_id);
--
    -- �S���ҕ���
    prc_set_xml('D', 'charge_dept', gr_header.user_dept, 10);
--
    -- �S���Җ�
    prc_set_xml('D', 'agent', gr_header.user_name, 14);
--
    -- �o�͓�
    prc_set_xml('D', 'exec_date', TO_CHAR(gr_header.exec_date,gc_char_dt_format));
--
    -- ���oFROM
    prc_set_xml('D', 'p_trans_ym_from', gr_header.proc_from_char);
--
    -- ���oto
    prc_set_xml('D', 'p_trans_ym_to', gr_header.proc_to_char);
--
    --���i�敪
    prc_set_xml('D', 'p_item_div_code', gr_param.prod_div);
    prc_set_xml('D', 'p_item_div_name', lv_prod_div_name, 20);
--
    --�󕥋敪
    prc_set_xml('D', 'p_rcv_pay_div_code', gr_param.rcv_pay_div);
    prc_set_xml('D', 'p_rcv_pay_div_name', lv_rcv_pay_div_name, 20);

--
    -- �w�b�_�[�I���^�O
    prc_set_xml('T', '/user_info');
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    --=====================================================
    prc_get_report_data(
        ot_data_rec   => gt_main_data   --    �擾���R�[�h�Q
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
--
    -- �f�[�^���J�n�^�O
    prc_set_xml('T', 'data_info');
    --���i�敪
    prc_set_xml('T', 'lg_prod_div');
    prc_set_xml('T', 'g_prod_div');
    --�i�ڋ敪
    prc_set_xml('T', 'lg_item_div');
    prc_set_xml('T', 'g_item_div');
    --�󕥋敪
    prc_set_xml('T', 'lg_rcv_pay_div');
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      --�L�[���ꔻ�f�p�ϐ�������
      ln_group_depth     := 0;
      lr_now_key.rcv_pay_div := gt_main_data(ln_loop_index).rcv_pay_div;
      lr_now_key.crowd_high  := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1);
      lr_now_key.crowd_mid   := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2);
      lr_now_key.crowd_low   := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3);
      lr_now_key.crowd_dtl   :=   lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4);
      lr_now_key.item_from   :=   gt_main_data(ln_loop_index).item_code_from;
      lr_now_key.item_to     :=   gt_main_data(ln_loop_index).item_code_to;
--
      -- =====================================================
      -- �I���^�O�쐬
      -- =====================================================
      -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_prod_div; --�J�n�^�O�\���p
        lb_isfirst := FALSE;
      ELSE
        --�L�[���ꔻ�f�@�ׂ������ɔ��f
        -- �ڌQ
        IF ( NVL(lr_now_key.crowd_dtl, lc_break ) <> lr_pre_key.crowd_dtl ) THEN
          prc_set_xml('T', '/lg_item');
          prc_set_xml('T', '/g_crowd_dtl');
          ln_group_depth := lc_depth_crowd_dtl;
--
          -- ���Q
          IF ( NVL(lr_now_key.crowd_low, lc_break ) <> lr_pre_key.crowd_low ) THEN
            prc_set_xml('T', '/lg_crowd_dtl');
            prc_set_xml('T', '/g_crowd_low');
            ln_group_depth := lc_depth_crowd_low;
--
            -- ���Q
            IF ( NVL(lr_now_key.crowd_mid, lc_break ) <> lr_pre_key.crowd_mid ) THEN
              prc_set_xml('T', '/lg_crowd_low');
              prc_set_xml('T', '/g_crowd_mid');
              ln_group_depth := lc_depth_crowd_mid;
--
              -- ��Q
              IF ( NVL(lr_now_key.crowd_high, lc_break ) <> lr_pre_key.crowd_high ) THEN
                prc_set_xml('T', '/lg_crowd_mid');
                prc_set_xml('T', '/g_crowd_high');
                ln_group_depth := lc_depth_crowd_high;
--
                -- �󕥋敪
                IF ( NVL(lr_now_key.rcv_pay_div, lc_break ) <> lr_pre_key.rcv_pay_div ) THEN
                  prc_set_xml('T', '/lg_crowd_high');
                  prc_set_xml('T', '/g_rcv_pay_div');
                  ln_group_depth := lc_depth_rcv_pay_div;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- =====================================================
      -- �J�n�^�O�쐬(�傫����
      -- =====================================================
      IF (ln_group_depth >= lc_depth_rcv_pay_div) THEN
        -- �󕥋敪
        prc_set_xml('T', 'g_rcv_pay_div');
        prc_set_xml('D', 'rcv_pay_div_code', gt_main_data(ln_loop_index).rcv_pay_div);
        prc_set_xml('T', 'lg_crowd_high');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_high) THEN
        -- ��Q
        prc_set_xml('T', 'g_crowd_high');
        prc_set_xml('D', 'crowd_lcode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1));
        prc_set_xml('T', 'lg_crowd_mid');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_mid) THEN
        -- ���Q
        prc_set_xml('T', 'g_crowd_mid');
        prc_set_xml('D', 'crowd_mcode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2));
        prc_set_xml('T', 'lg_crowd_low');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_low) THEN
        -- ���Q
        prc_set_xml('T', 'g_crowd_low');
        prc_set_xml('D', 'crowd_scode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3));
        prc_set_xml('T', 'lg_crowd_dtl');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_dtl) THEN
        -- �ڌQ
        prc_set_xml('T', 'g_crowd_dtl');
        prc_set_xml('D', 'crowd_code'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4));
        prc_set_xml('T', 'lg_item');
      END IF;
--
      -- �o����
      ln_qty         := ln_qty        + NVL(gt_main_data(ln_loop_index).trans_qty, 0);
      -- ��W�����z
      ln_to_gen      := ln_to_gen     + NVL(gt_main_data(ln_loop_index).to_cost, 0);
      -- �����ۋ��z
      ln_from_gen    := ln_from_gen   + NVL(gt_main_data(ln_loop_index).from_cost, 0);
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      IF (  (ln_loop_index = gt_main_data.COUNT)
         OR (gt_main_data(ln_loop_index + 1).rcv_pay_div
             || SUBSTR(gt_main_data(ln_loop_index + 1).gun_code , 1, 4)
             <> lr_now_key.crowd_dtl)
         OR (gt_main_data(ln_loop_index + 1).item_code_from <> lr_now_key.item_from )
         OR (gt_main_data(ln_loop_index + 1).item_code_to   <> lr_now_key.item_to   )
         ) THEN
--
        --���׊J�n
        prc_set_xml('T', 'g_item');
--
        --��i��
        prc_set_xml('D', 'item_code_to', gt_main_data(ln_loop_index).item_code_to);
        prc_set_xml('D', 'item_name_to', gt_main_data(ln_loop_index).item_name_to, 20);
--
        --���i��
        prc_set_xml('D', 'item_code_from', gt_main_data(ln_loop_index).item_code_from);
        prc_set_xml('D', 'item_name_from', gt_main_data(ln_loop_index).item_name_from, 20);
--
        --�U�֐���
        prc_set_xml('Z', 'quantity', ln_qty);
--
        --�W���P��
        IF (ln_qty != 0) THEN
          ln_to_price := ln_to_gen / ln_qty;
        END IF;
        prc_set_xml('Z', 'standard_price', ln_to_price);
--
        --�W������
        prc_set_xml('Z', 'standard_cost', ln_to_gen);
--
        --�U�֌����ےP��
        IF (ln_qty != 0 ) THEN
          ln_from_price := ln_from_gen / ln_qty ;
        END IF;
        prc_set_xml('Z', 'actual_price', ln_from_price);
--
        --�U�֌����ی���
        prc_set_xml('Z', 'actual_cost', ln_from_gen);
--
        --�P������
        ln_sai_tan := ln_to_price - ln_from_price;
        prc_set_xml('Z', 'difference_price', ln_sai_tan);
--
        --��������
        ln_sai_gen := ln_to_gen - ln_from_gen;
        prc_set_xml('Z', 'difference_cost', ln_sai_gen);
--
        -- ���ׂP�s�I��
        prc_set_xml('T', '/g_item');
--
        --���v���Z
        ln_sum_qty        := ln_sum_qty        + ln_qty;
        ln_sum_to_gen     := ln_sum_to_gen     + ln_to_gen;
        ln_sum_from_gen   := ln_sum_from_gen   + ln_from_gen;
        ln_sum_sai_gen    := ln_sum_sai_gen    + ln_sai_gen;
--
        -- ������
        ln_qty         := 0;         -- �o����
        ln_to_price    := 0;         -- ��W������
        ln_to_gen      := 0;         -- ��W�����z
        ln_from_price  := 0;         -- �����ےP��
        ln_from_gen    := 0;         -- �����ۋ��z
        ln_sai_tan     := 0;         -- �P������
        ln_sai_gen     := 0;         -- ��������
      END IF;
--
      --���㏈��
      lr_pre_key := lr_now_key;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I���^�O
    -- =====================================================
    prc_set_xml('T', '/lg_item');
    prc_set_xml('T', '/g_crowd_dtl');
    prc_set_xml('T', '/lg_crowd_dtl');
    prc_set_xml('T', '/g_crowd_low');
    prc_set_xml('T', '/lg_crowd_low');
    prc_set_xml('T', '/g_crowd_mid');
    prc_set_xml('T', '/lg_crowd_mid');
    prc_set_xml('T', '/g_crowd_high');
    prc_set_xml('T', '/lg_crowd_high');
--
    --�󕥃O���[�v���ɍ��v��\��
    -- �P���v�Z
    IF (ln_sum_qty != 0) THEN
      ln_sum_to_price   := ln_sum_to_gen   / ln_sum_qty;
      ln_sum_from_price := ln_sum_from_gen / ln_sum_qty;
      ln_sum_sai_tan    := ln_sum_to_price - ln_sum_from_price;
    END IF;
--
    --���v�\���t���O
    prc_set_xml('D', 'switch', 1);
    --�o�����v
    prc_set_xml('Z', 'sum_quantity',         ln_sum_qty);
    --��P������
    prc_set_xml('Z', 'sum_standard_price',   ln_sum_to_price);
    --�挴���v
    prc_set_xml('Z', 'sum_standard_cost',    ln_sum_to_gen);
    --���P������
    prc_set_xml('Z', 'sum_actual_price',     ln_sum_from_price);
    --������
    prc_set_xml('Z', 'sum_actual_cost',      ln_sum_from_gen);
    --�P������
    prc_set_xml('Z', 'sum_difference_price', ln_sum_sai_tan);
    --��������
    prc_set_xml('Z', 'sum_difference_cost',  ln_sum_sai_gen);
--
    prc_set_xml('T', '/g_rcv_pay_div');
    prc_set_xml('T', '/lg_rcv_pay_div');
    prc_set_xml('T', '/g_item_div');
    prc_set_xml('T', '/lg_item_div');
    prc_set_xml('T', '/g_prod_div');
    prc_set_xml('T', '/lg_prod_div');
--
    -- �f�[�^���I���^�O
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,'app-xxcmn-10122'  ) ;
--
--#################################  �Œ��O������ start   ####################################
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from       IN    VARCHAR2  -- �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  -- �����N��to
     ,iv_prod_div        IN    VARCHAR2  -- ���i�敪
     ,iv_item_div        IN    VARCHAR2  -- �i�ڋ敪
     ,iv_rcv_pay_div     IN    VARCHAR2  -- �󕥋敪
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
     ,ov_errbuf          OUT   VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         OUT   VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          OUT   VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� start   ####################
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
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� start   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ���̓p�����[�^�ێ�
    gr_param.proc_from       := iv_proc_from      ; -- �����N��FROM
    gr_param.proc_to         := iv_proc_to        ; -- �����N��to
    gr_param.prod_div        := iv_prod_div       ; -- ���i�敪
    gr_param.item_div        := iv_item_div       ; -- �i�ڋ敪
    gr_param.rcv_pay_div     := iv_rcv_pay_div    ; -- �󕥋敪
    gr_param.crowd_type      := iv_crowd_type     ; -- �W�v���
    gr_param.crowd_code      := iv_crowd_code     ; -- �Q�R�[�h
    gr_param.acnt_crowd_code := iv_acnt_crowd_code; -- �o���Q�R�[�h
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
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
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �������o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '     <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '       <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '               <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                   </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '               </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </g_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '           </lg_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '     </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '   </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' </root>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �������w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUt, '<root>' ) ;
--
      -- �������f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �������^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �������t�b�_�[�o��
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
--#################################  �Œ��O������ start   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  -- �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  -- �����N��to
     ,iv_prod_div        IN    VARCHAR2  -- ���i�敪
     ,iv_item_div        IN    VARCHAR2  -- �i�ڋ敪
     ,iv_rcv_pay_div     IN    VARCHAR2  -- �󕥋敪
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
    )
--
--###########################  �Œ蕔 start   ###########################
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
    submain(
        iv_proc_from       => iv_proc_from         -- �����N��FROM
       ,iv_proc_to         => iv_proc_to           -- �����N��to
       ,iv_prod_div        => iv_prod_div          -- ���i�敪
       ,iv_item_div        => iv_item_div          -- �i�ڋ敪
       ,iv_rcv_pay_div     => iv_rcv_pay_div       -- �󕥋敪
       ,iv_crowd_type      => iv_crowd_type        -- �W�v���
       ,iv_crowd_code      => iv_crowd_code       -- �Q�R�[�h
       ,iv_acnt_crowd_code => iv_acnt_crowd_code  -- �o���Q�R�[�h
       ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 start   #####################################################
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
END xxcmn770009c ;
/
