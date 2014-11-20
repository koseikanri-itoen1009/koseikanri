CREATE OR REPLACE PACKAGE BODY xxcmn770025c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770025C(body)
 * Description      : �d�����ѕ\�쐬
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77E)
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  fnc_conv_xml             �w�l�k�^�O�ɕϊ�����
 *  prc_create_xml_data_zero �w�l�k�f�[�^�쐬(0��)
 *  prc_create_xml_data_sum  �w�l�k�f�[�^�쐬(���v)
 *  prc_out_xml              �w�l�k�o�͏���
 *  prc_initialize           �O����
 *  prc_get_report_data      ���׃f�[�^�擾(E-1)
 *  prc_create_xml_data_line �w�l�k�f�[�^�쐬(����)
 *  prc_create_xml_data      �w�l�k�f�[�^�쐬
 *  prc_set_param            �p�����[�^�̎擾
 *  submain                  ���C�������v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   T.Endou          �V�K�쐬
 *  2008/05/16    1.1   T.Ikehara        �s�ID:77E-17�Ή�  �����N���p��YYYYM���͑Ή�
 *  2008/05/30    1.2   T.Endou          ���ےP���擾���@�̕ύX
 *  2008/06/24    1.3   I.Higa           �f�[�^���������ڂł��O���o�͂���
 *  2008/06/25    1.4   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/22    1.5   T.Endou          ���y�[�W���A�w�b�_���o�Ȃ��p�^�[���Ή�
 *  2008/10/14    1.6   A.Shiina         T_S_524�Ή�
 *  2008/10/28    1.7   H.Itou           T_S_524�Ή�(�đΉ�)
 *  2008/11/13    1.8   A.Shiina         �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.9   N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/28    1.10  N.Yoshida        �{��#182�Ή�
 *  2008/12/04    1.11  N.Yoshida        �{��#389�Ή�
 *  2008/12/05    1.12  A.Shiina         �{��#500�Ή�
 *  2008/12/05    1.13  A.Shiina         �{��#473�Ή�
 *  2008/12/12    1.14  A.Shiina         �{��#425�Ή�
 *  2008/12/16    1.15  A.Shiina         �{��#754�Ή�
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770025C'; -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '�d�����ѕ\';   -- ���[��
  gd_exec_date              CONSTANT DATE         := SYSDATE;        -- ���{��
--
  gv_xxcmn_ctr              CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE'; -- �����
  gv_cat_set_name_prod_div  CONSTANT VARCHAR2(8)  := '���i�敪';
  gv_cat_set_name_item_div  CONSTANT VARCHAR2(8)  := '�i�ڋ敪';
-- 2008/10/28 H.Itou Add Start T_S_524�Ή�(�đΉ�)
  gv_min_date               CONSTANT VARCHAR2(20) := '1900/01/01 00:00:00';
  gv_max_date               CONSTANT VARCHAR2(20) := '9999/12/31 23:59:59';
-- 2008/10/28 H.Itou Add End
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ; -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;  -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_yyyymm_format   CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_yyyy_format     CONSTANT VARCHAR2(30) := 'YYYY' ;
  gc_char_mm_format       CONSTANT VARCHAR2(30) := 'MM' ;
--
  gn_zero                 CONSTANT NUMBER := 0;
  gn_one                  CONSTANT NUMBER := 1;
  gn_2                    CONSTANT NUMBER := 2;
  gn_3                    CONSTANT NUMBER := 3;
  gn_4                    CONSTANT NUMBER := 4;
  gn_10                   CONSTANT NUMBER := 10;
  gn_11                   CONSTANT NUMBER := 11;
  gn_14                   CONSTANT NUMBER := 14;
  gn_15                   CONSTANT NUMBER := 15;
  gn_16                   CONSTANT NUMBER := 16;
  gn_20                   CONSTANT NUMBER := 20;
  gn_21                   CONSTANT NUMBER := 21;
  gn_30                   CONSTANT NUMBER := 30;
  gn_100                  CONSTANT NUMBER := 100;
  gv_y                    CONSTANT VARCHAR2(1) := 'Y';
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  gv_ja                   CONSTANT VARCHAR2(2) := 'JA';
  gv_ja_year              CONSTANT VARCHAR2(2) := '�N';
  gv_ja_month             CONSTANT VARCHAR2(2) := '��';
--
  gn_lot_yes              CONSTANT NUMBER := 1; -- ���b�g�Ǘ�����
  -- �����敪
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0'; --���ی���
  gc_cost_st              CONSTANT VARCHAR2(1) := '1'; --�W������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
    proc_from       VARCHAR2(6)    -- 01 : �����N��(FROM)
   ,proc_to         VARCHAR2(6)    -- 02 : �����N��(TO)
   ,prod_div        VARCHAR2(1)    -- 03 : ���i�敪
   ,item_div        VARCHAR2(1)    -- 04 : �i�ڋ敪
   ,result_post     VARCHAR2(4)    -- 05 : ���ѕ���
   ,party_code      VARCHAR2(15)   -- 06 : �d����
   ,crowd_type      VARCHAR2(1)    -- 07 : �Q���
   ,crowd_code      VARCHAR2(4)    -- 08 : �Q�R�[�h
   ,acnt_crowd_code VARCHAR2(4)    -- 09 : �o���Q�R�[�h
   ) ;
--
  -- ��s�������f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
    result_post      xxcmn_rcv_pay_mst_porc_po_v.result_post%TYPE   -- ���ѕ���
   ,location_name    xxcmn_locations2_v.location_name%TYPE          -- ���Ə���
   ,item_div         xxcmn_lot_each_item_v.item_div%TYPE            -- �i�ڋ敪
   ,item_div_name    xxcmn_categories_v.description%TYPE            -- �i�ڋ敪��
   ,vendor_code      xxcmn_vendors2_v.segment1%TYPE                 -- �d����R�[�h
   ,vendor_name      xxcmn_vendors2_v.vendor_name%TYPE              -- �d���於
   ,crowd_code       xxcmn_lot_each_item_v.crowd_code%TYPE          -- �Q���� or �o���Q����
   ,item_code        xxcmn_lot_each_item_v.item_code%TYPE           -- �i�ڃR�[�h
   ,item_name        xxcmn_lot_each_item_v.item_name%TYPE           -- �i�ږ���
   ,item_um          xxcmn_lot_each_item_v.item_um%TYPE             -- �P��
   ,item_atr15       xxcmn_lot_each_item_v.item_attribute15%TYPE    -- �����Ǘ��敪
   ,lot_ctl          xxcmn_lot_each_item_v.lot_ctl%TYPE             -- ���b�g�Ǘ��敪
   ,trans_qty        NUMBER                                         -- ����
   ,purchases_price  NUMBER                                         -- �d���P��(���b�g)
   ,powder_price     xxcmn_rcv_pay_mst_porc_po_v.powder_price%TYPE     -- ������P��
   ,commission_price xxcmn_rcv_pay_mst_porc_po_v.commission_price%TYPE -- ���K�P��
   ,c_amt            NUMBER                                         -- ���K���z ���K�P�� * ����
   ,assessment       xxcmn_rcv_pay_mst_porc_po_v.assessment%TYPE       -- ���ۋ�
   ,stnd_unit_price  xxcmn_stnd_unit_price_v.stnd_unit_price%TYPE   -- �W������
   ,j_amt            NUMBER                                         -- ���ےP�� * ����
   ,s_amt            NUMBER                                         -- �d���P��(���b�g) * ����
-- 2008/12/05 v1.13 ADD START
   ,commission_tax   NUMBER                                         -- ����œ�(���K)
   ,payment_tax      NUMBER                                         -- ����œ�(�x��)
-- 2008/12/05 v1.13 ADD END
   ,c_tax            NUMBER                                         -- �����
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- �S����
  gn_para_vendor_id         NUMBER; -- ���̓p���d����ID
--
  gv_report_id        VARCHAR2(12);                           -- ���[ID
  gv_prod_div_name    xxcmn_categories_v.description%TYPE;    -- ���i�敪
  gv_item_div_name    xxcmn_categories_v.description%TYPE;    -- �i�ڋ敪
  gv_result_post_name xxcmn_locations_v.location_name%TYPE;   -- ���ѕ���
  gv_party_code_name  xxcmn_vendors_v.vendor_name%TYPE;       -- �d����
  gv_crowd_type       xxcmn_lookup_values_v.description%TYPE; -- �Q���
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_user_expt       EXCEPTION;        -- ���[�U�[�ɂĒ�`��������O
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_zero
   * Description      : �w�l�k�f�[�^�쐬(0��)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_zero(
      ov_errbuf                    OUT VARCHAR2       -- �װ�ү����
     ,ov_retcode                   OUT VARCHAR2       -- ���ݥ����
     ,ov_errmsg                    OUT VARCHAR2       -- հ�ް��װ�ү����
     ,ir_param                     IN  rec_param_data -- �p�����[�^
     ,iot_xml_idx                  IN OUT NUMBER      -- �w�l�k�ް���ޕ\�̲��ޯ��
     ,iot_xml_data_table           IN OUT XML_DATA    -- XML�ް�
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_zero' ; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_no_data  VARCHAR2(5000);   -- �f�[�^�Ȃ����b�Z�[�W
--
  BEGIN
--
    -- =====================================================
    -- �O�����b�Z�[�W�o��
    -- =====================================================
    lv_errmsg_no_data := xxcmn_common_pkg.get_msg( gc_application_po
                                                 ,'APP-XXPO-00009' ) ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- ���ѕ���G�J�n�^�O
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'g_result_post' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- �i�ڋ敪LG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪G�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.party_code IS NULL ) THEN
      -- �d����LG�J�n�^�O�o��
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
      -- �d����G�J�n�^�O�o��
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'g_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- ��QLG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ��QG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QLG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd_m' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd_s' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QLG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 0�����b�Z�[�W
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'msg' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := lv_errmsg_no_data;
    -- ���QG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QLG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd_s' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ���QLG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd_m' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ��QG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- ��QLG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.party_code IS NULL ) THEN
      -- �d����G�I���^�O�o��
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/g_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
      -- �d����LG�I���^�O�o��
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- �i�ڋ敪G�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪LG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- ���ѕ���G�I���^�O
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/g_result_post' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
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
  END prc_create_xml_data_zero ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_sum
   * Description      : �w�l�k�f�[�^�쐬(���v)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_sum(
      ov_errbuf                    OUT VARCHAR2       -- �װ�ү����
     ,ov_retcode                   OUT VARCHAR2       -- ���ݥ����
     ,ov_errmsg                    OUT VARCHAR2       -- հ�ް��װ�ү����
     ,iot_xml_idx                  IN OUT NUMBER      -- �w�l�k�ް���ޕ\�̲��ޯ��
     ,iot_xml_data_table           IN OUT XML_DATA    -- XML�ް�
     ,in_sum_quantity              IN  NUMBER         -- ���ʌv
     ,in_sum_order_amount          IN  NUMBER         -- �d�����z�v
     ,in_sum_commission_price      IN  NUMBER         -- ���K�v
     ,in_sum_commission_tax_amount IN  NUMBER         -- ����Ōv(���K)
     ,in_sum_commission_amount     IN  NUMBER         -- ���K���z
     ,in_sum_assess_amount         IN  NUMBER         -- ���ۋ��v
     ,in_sum_payment               IN  NUMBER         -- �x���v
     ,in_sum_payment_amount_tax    IN  NUMBER         -- ����Ōv(�x��)
     ,in_sum_payment_amount        IN  NUMBER         -- �x�����z�v
     ,in_sum_standard_amount       IN  NUMBER         -- �W�����z�v
     ,in_sum_difference_amount     IN  NUMBER         -- ���ٌv
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_sum' ; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
    -- =====================================================
    -- �����v�o��
    -- =====================================================
    -- �����vLG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �����vG�J�n�^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �����v�o�̓t���O
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_flag' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := gv_y;
    -- ���ʌv
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_quantity' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_quantity ;
    -- �d�����z�v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_order_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_order_amount;
    -- ���K�v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_price' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_price;
    -- ����Ōv(���K)
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_tax_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_tax_amount;
    -- ���K���z
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_amount;
    -- ���ۋ��v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_assess_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_assess_amount;
    -- �x���v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment;
    -- ����Ōv(�x��)
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment_amount_tax' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment_amount_tax;
    -- �x�����z�v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment_amount;
    -- �W�������v
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_standard_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_standard_amount;
    -- ���ٌv
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_difference_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_difference_amount;
    -- �����vG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �����vLG�I���^�O�o��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data_sum ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml
   * Description      : XML�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml(
      ov_errbuf         OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data -- ���̓p�����[�^�Q
     ,it_xml_data_table IN  XML_DATA       -- �擾���R�[�h�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml' ; -- �v���O������
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
    lv_xml_string        VARCHAR2(32000);
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
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- �w�l�k�w�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- �w�l�k�f�[�^���o��
    <<xml_data_table>>
    FOR i IN 1 .. it_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := fnc_conv_xml(
                          iv_name   => it_xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => it_xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => it_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- �w�l�k�t�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN     rec_param_data   -- ���̓p�����[�^�Q
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
    -- *** ���[�J���萔 ***
    cv_x_mov      CONSTANT VARCHAR2(20) := 'XXCMN_MC_OUPUT_DIV';
    cv_t          CONSTANT VARCHAR2(1) := 'T';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E��O���� ***
    get_value_expt    EXCEPTION ;     -- �l�擾�G���[
    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- �����
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���[ID�ݒ�
    -- ====================================================
    IF ( (ir_param.result_post IS NULL)
      AND (ir_param.party_code IS NULL) ) THEN
      -- ���ѕ����E�d����Ƃ��Ƀu�����N�w�� XXCMN770054
      gv_report_id := xxcmn770015c.program_id_04 || cv_t;
    ELSIF ( ir_param.result_post IS NULL ) THEN
      -- ���ѕ����̂݃u�����N�w�� XXCMN770052
      gv_report_id := xxcmn770015c.program_id_02 || cv_t;
    ELSIF ( ir_param.party_code IS NULL ) THEN
      -- �d����̂݃u�����N�w�� XXCMN770053
      gv_report_id := xxcmn770015c.program_id_03 || cv_t;
    ELSE
      -- ���ѕ����E�d����Ƃ��Ƀu�����N�w��O XXCMN770051
      gv_report_id := xxcmn770015c.program_id_01 || cv_t;
    END IF;
--
    -- ====================================================
    -- �e�p�����[�^���̎擾
    -- ====================================================
    -- ���i�敪
    BEGIN
      SELECT xcv.description
      INTO   gv_prod_div_name
      FROM   xxcmn_categories_v xcv
      WHERE  xcv.category_set_name = gv_cat_set_name_prod_div
        AND  xcv.segment1          = ir_param.prod_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �i�ڋ敪
    BEGIN
      SELECT xcv.description
      INTO   gv_item_div_name
      FROM   xxcmn_categories_v xcv
      WHERE  xcv.category_set_name = gv_cat_set_name_item_div
        AND  xcv.segment1          = ir_param.item_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �Q���
    BEGIN
      SELECT xlvv.description
      INTO   gv_crowd_type
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  lookup_type      = cv_x_mov
        AND  xlvv.lookup_code = ir_param.crowd_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ���ѕ���
    BEGIN
      SELECT xlv.location_name
      INTO   gv_result_post_name
      FROM   xxcmn_locations_v xlv
      WHERE  xlv.location_code = ir_param.result_post;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �d����
    BEGIN
      SELECT xvv.vendor_name
            ,xvv.vendor_id
      INTO   gv_party_code_name
            ,gn_para_vendor_id
      FROM   xxcmn_vendors_v xvv
      WHERE  xvv.segment1      = ir_param.party_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(E-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ov_errbuf     OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN  rec_param_data            -- ���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- �擾���R�[�h�Q
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
    cv_crowd_type        CONSTANT VARCHAR2( 1) := '3'; -- �Q��
    cv_crowd_type_acnt   CONSTANT VARCHAR2( 1) := '4'; -- �o���Q��
    cv_deliver           CONSTANT VARCHAR2( 7) := 'DELIVER';          -- ���
    cv_return_to_vendor  CONSTANT VARCHAR2(16) := 'RETURN TO VENDOR'; -- �ԕi
    cv_po                CONSTANT VARCHAR2( 2) := 'PO';
    cv_porc              CONSTANT VARCHAR2( 4) := 'PORC';
    cv_adji              CONSTANT VARCHAR2( 4) := 'ADJI';
    cv_x201              CONSTANT VARCHAR2( 4) := 'X201'; -- �d����ԕi
-- 2008/11/13 v1.8 ADD START
    cv_rma               CONSTANT VARCHAR2( 3) := 'RMA';
-- 2008/11/13 v1.8 ADD END
-- 2008/12/16 v1.15 ADD START
    cv_money_fix         CONSTANT VARCHAR2(2)  := '35';
    cv_cancel            CONSTANT VARCHAR2(2)  := '99';
-- 2008/12/16 v1.15 ADD END
    cv_cat_set_name_mtof CONSTANT VARCHAR2(30) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
--
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
--
-- 2008/10/14 v1.6 ADD START
    cv_zero              CONSTANT VARCHAR2( 1) := '0';
-- 2008/10/14 v1.6 ADD END
    -- *** ���[�J���E�ϐ� ***
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_in         VARCHAR2(1000) ;
    lt_lkup_code  fnd_lookup_values.lookup_code%TYPE;
--
-- 2008/10/14 v1.6 ADD START
    lv_select     VARCHAR2(32000) ;
    lv_porc_po    VARCHAR2(32000) ;
    lv_adji       VARCHAR2(32000) ;
    lv_group      VARCHAR2(32000) ;
    lv_order      VARCHAR2(32000) ;
--
-- 2008/10/14 v1.6 ADD END
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/14 v1.6 DELETE START
/*
--yutsuzuk add
    CURSOR get_cur01 IS
      SELECT mst.result_post           AS result_post
            ,mst.location_name         AS location_name
            ,mst.item_div              AS item_div
            ,mst.item_div_name         AS item_div_name
            ,mst.segment1              AS vendor_code
            ,mst.vendor_name           AS vendor_name
            ,mst.crowd_code            AS crowd_code
            ,mst.item_code             AS item_code
            ,mst.item_s_name           AS item_s_name
            ,mst.item_um               AS item_um
            ,mst.item_atr15            AS item_atr15
            ,mst.lot_ctl               AS lot_ctl
            ,SUM(mst.trans_qty)        AS trans_qty
            ,AVG(mst.purchases_price)  AS purchases_price
            ,AVG(mst.powder_price)     AS powder_price
            ,AVG(mst.commission_price) AS commission_price
            ,SUM(mst.commission_price * mst.trans_qty) AS c_amt
            ,SUM(mst.assessment)       AS assessment
            ,AVG(mst.stnd_unit_price)  AS stnd_unit_price
            ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt
            ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt
            ,lt_lkup_code              AS c_tax
      FROM  (-- �w���֘A
             SELECT /*+ leading(itp gic1 mcb1 rsl rt pha pla plla) use_nl(itp gic1 mcb1)*/
/*
                    pha.attribute10         AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,pha.vendor_id           AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itp.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itp.item_id
                    AND    xlc.lot_id  = itp.lot_id)  AS purchases_price
                   ,NVL(plla.attribute2,'0') AS powder_price
                   ,NVL(plla.attribute4,'0') AS commission_price
                   ,NVL(plla.attribute7,'0') AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_pnd              itp
                   ,rcv_shipment_lines       rsl
                   ,rcv_transactions         rt
                   ,po_headers_all           pha
                   ,po_lines_all             pla
                   ,po_line_locations_all    plla
                   ,ic_item_mst_b            iimb
                   ,xxcmn_item_mst_b         ximb
                   ,gmi_item_categories      gic1
                   ,mtl_categories_b         mcb1
                   ,gmi_item_categories      gic2
                   ,mtl_categories_b         mcb2
                   ,mtl_categories_tl        mct2
                   ,gmi_item_categories      gic3
                   ,mtl_categories_b         mcb3
                   ,gmi_item_categories      gic4
                   ,mtl_categories_b         mcb4
                   ,xxcmn_vendors2_v         xvv
                   ,hr_locations_all         hl
                   ,xxcmn_locations_all      xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itp.doc_type                = cv_porc
             AND    itp.completed_ind           = gn_one
             AND    itp.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itp.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iimb.item_id                = itp.item_id
             AND    ximb.item_id                = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
             AND    gic1.item_id                = itp.item_id
             AND    gic1.category_set_id        = cn_prod_class_id
             AND    mcb1.category_id            = gic1.category_id
             AND    mcb1.segment1               = ir_param.prod_div
             AND    gic2.item_id                = itp.item_id
             AND    gic2.category_set_id        = cn_item_class_id
             AND    mcb2.category_id            = gic2.category_id
             AND    mct2.category_id            = mcb2.category_id
             AND    mct2.language               = gv_ja
             AND    gic3.item_id                = itp.item_id
             AND    gic3.category_set_id        = cn_crowd_code_id
             AND    mcb3.category_id            = gic3.category_id
             AND    gic4.item_id                = itp.item_id
             AND    gic4.category_set_id        = cn_acnt_crowd_id
             AND    mcb4.category_id            = gic4.category_id
             AND    rsl.shipment_header_id      = itp.doc_id
             AND    rsl.line_num                = itp.doc_line
             AND    rt.transaction_id           = itp.line_id
             AND    rt.shipment_line_id         = rsl.shipment_line_id
             AND    rsl.po_header_id            = pha.po_header_id
             AND    rsl.po_line_id              = pla.po_line_id
             AND    pla.po_line_id              = plla.po_line_id
             AND    rsl.source_document_code    = cv_po
             AND    rt.transaction_type     IN (cv_deliver
                                               ,cv_return_to_vendor)
             AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itp.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = pha.vendor_id
             AND    hl.location_code            = pha.attribute10
             AND    hl.location_id              = xl.location_id
             AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itp.trans_date)
             AND    xsupv.start_date_active     < (TRUNC(itp.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itp.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id                = itp.item_id
             UNION ALL -- �݌ɒ���(�d����ԕi)
             SELECT /*+ leading(itc gic1 mcb1 iaj ijm xrrt ) use_nl(itc gic1 mcb1) */
/*
                    xrrt.department_code    AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,xrrt.vendor_id          AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itc.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itc.item_id
                    AND    xlc.lot_id  = itc.lot_id) AS purchases_price
                   ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price,0)) AS powder_price
                   ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price,0))  AS commission_price
                   ,TO_CHAR(NVL(xrrt.fukakin_price,0)) AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_cmp               itc
                   ,ic_adjs_jnl               iaj
                   ,ic_jrnl_mst               ijm
                   ,ic_item_mst_b             iimb
                   ,xxpo_rcv_and_rtn_txns     xrrt
                   ,xxcmn_item_mst_b          ximb
                   ,gmi_item_categories       gic1
                   ,mtl_categories_b          mcb1
                   ,gmi_item_categories       gic2
                   ,mtl_categories_b          mcb2
                   ,mtl_categories_tl         mct2
                   ,gmi_item_categories       gic3
                   ,mtl_categories_b          mcb3
                   ,gmi_item_categories       gic4
                   ,mtl_categories_b          mcb4
                   ,xxcmn_vendors2_v          xvv
                   ,hr_locations_all          hl
                   ,xxcmn_locations_all       xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itc.doc_type        = cv_adji
             AND    itc.reason_code     = cv_x201
             AND    itc.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itc.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iaj.trans_type      = itc.doc_type
             AND    iaj.doc_id          = itc.doc_id
             AND    iaj.doc_line        = itc.doc_line
             AND    ijm.journal_id      = iaj.journal_id
             AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1)
             AND    iimb.item_id        = itc.item_id
             AND    ximb.item_id        = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
             AND    gic1.item_id        = itc.item_id
             AND    gic1.category_set_id = cn_prod_class_id
             AND    mcb1.category_id    = gic1.category_id
             AND    mcb1.segment1       = ir_param.prod_div
             AND    gic2.item_id        = itc.item_id
             AND    gic2.category_set_id = cn_item_class_id
             AND    mcb2.category_id    = gic2.category_id
             AND    mct2.category_id    = mcb2.category_id
             AND    mct2.language       = gv_ja
             AND    gic3.item_id        = itc.item_id
             AND    gic3.category_set_id = cn_crowd_code_id
             AND    mcb3.category_id    = gic3.category_id
             AND    gic4.item_id        = itc.item_id
             AND    gic4.category_set_id = cn_acnt_crowd_id
             AND    mcb4.category_id    = gic4.category_id
             AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itc.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = xrrt.vendor_id
             AND    hl.location_code         = xrrt.department_code
             AND    hl.location_id           = xl.location_id
             and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itc.trans_date)
             and    xsupv.start_date_active <(TRUNC(itc.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itc.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id               = itc.item_id
            ) mst
      GROUP BY mst.result_post
              ,mst.location_name
              ,mst.item_div
              ,mst.item_div_name
              ,mst.segment1
              ,mst.vendor_name
              ,mst.crowd_code
              ,mst.item_code
              ,mst.item_s_name
              ,mst.item_um
              ,mst.item_atr15
              ,mst.lot_ctl
      ORDER BY mst.result_post
              ,mst.item_div
              ,mst.segment1
              ,mst.crowd_code
              ,mst.item_code
    ;
--yutsuzuk add
--
--yutsuzuk add
    CURSOR get_cur02 IS
      SELECT mst.result_post           AS result_post
            ,mst.location_name         AS location_name
            ,mst.item_div              AS item_div
            ,mst.item_div_name         AS item_div_name
            ,mst.segment1              AS vendor_code
            ,mst.vendor_name           AS vendor_name
            ,mst.crowd_code            AS crowd_code
            ,mst.item_code             AS item_code
            ,mst.item_s_name           AS item_s_name
            ,mst.item_um               AS item_um
            ,mst.item_atr15            AS item_atr15
            ,mst.lot_ctl               AS lot_ctl
            ,SUM(mst.trans_qty)        AS trans_qty
            ,AVG(mst.purchases_price)  AS purchases_price
            ,AVG(mst.powder_price)     AS powder_price
            ,AVG(mst.commission_price) AS commission_price
            ,SUM(mst.commission_price * mst.trans_qty) AS c_amt
            ,SUM(mst.assessment)       AS assessment
            ,AVG(mst.stnd_unit_price)  AS stnd_unit_price
            ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt
            ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt
            ,lt_lkup_code              AS c_tax
      FROM  (-- �w���֘A
             SELECT /*+ leading(itp gic1 mcb1 gic2 mcb2 rsl rt pha pla plla) use_nl(itp gic1 mcb1 gic2 mcb2)*/
/*
                    pha.attribute10         AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,pha.vendor_id           AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itp.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itp.item_id
                    AND    xlc.lot_id  = itp.lot_id)  AS purchases_price
                   ,NVL(plla.attribute2,'0') AS powder_price
                   ,NVL(plla.attribute4,'0') AS commission_price
                   ,NVL(plla.attribute7,'0') AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_pnd              itp
                   ,rcv_shipment_lines       rsl
                   ,rcv_transactions         rt
                   ,po_headers_all           pha
                   ,po_lines_all             pla
                   ,po_line_locations_all    plla
                   ,ic_item_mst_b            iimb
                   ,xxcmn_item_mst_b         ximb
                   ,gmi_item_categories      gic1
                   ,mtl_categories_b         mcb1
                   ,gmi_item_categories      gic2
                   ,mtl_categories_b         mcb2
                   ,mtl_categories_tl        mct2
                   ,gmi_item_categories      gic3
                   ,mtl_categories_b         mcb3
                   ,gmi_item_categories      gic4
                   ,mtl_categories_b         mcb4
                   ,xxcmn_vendors2_v         xvv
                   ,hr_locations_all         hl
                   ,xxcmn_locations_all      xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itp.doc_type                = cv_porc
             AND    itp.completed_ind           = gn_one
             AND    itp.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itp.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iimb.item_id                = itp.item_id
             AND    ximb.item_id                = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
             AND    gic1.item_id                = itp.item_id
             AND    gic1.category_set_id        = cn_prod_class_id
             AND    mcb1.category_id            = gic1.category_id
             AND    mcb1.segment1               = ir_param.prod_div
             AND    gic2.item_id                = itp.item_id
             AND    gic2.category_set_id        = cn_item_class_id
             AND    mcb2.category_id            = gic2.category_id
             AND    mct2.category_id            = mcb2.category_id
             AND    mct2.language               = gv_ja
             AND    mcb2.segment1               = ir_param.item_div
             AND    gic3.item_id                = itp.item_id
             AND    gic3.category_set_id        = cn_crowd_code_id
             AND    mcb3.category_id            = gic3.category_id
             AND    gic4.item_id                = itp.item_id
             AND    gic4.category_set_id        = cn_acnt_crowd_id
             AND    mcb4.category_id            = gic4.category_id
             AND    rsl.shipment_header_id      = itp.doc_id
             AND    rsl.line_num                = itp.doc_line
             AND    rt.transaction_id           = itp.line_id
             AND    rt.shipment_line_id         = rsl.shipment_line_id
             AND    rsl.po_header_id            = pha.po_header_id
             AND    rsl.po_line_id              = pla.po_line_id
             AND    pla.po_line_id              = plla.po_line_id
             AND    rsl.source_document_code    = cv_po
             AND    rt.transaction_type     IN (cv_deliver
                                               ,cv_return_to_vendor)
             AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itp.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = pha.vendor_id
             AND    hl.location_code            = pha.attribute10
             AND    hl.location_id              = xl.location_id
             AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itp.trans_date)
             AND    xsupv.start_date_active     < (TRUNC(itp.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itp.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id                = itp.item_id
             UNION ALL -- �݌ɒ���(�d����ԕi)
             SELECT /*+ leading(itc gic1 mcb1 gic2 mcb2 iaj ijm xrrt ) use_nl(itc gic1 mcb1 gic2 mcb2) */
/*
                    xrrt.department_code    AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,xrrt.vendor_id          AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itc.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itc.item_id
                    AND    xlc.lot_id  = itc.lot_id) AS purchases_price
                   ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price,0)) AS powder_price
                   ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price,0))  AS commission_price
                   ,TO_CHAR(NVL(xrrt.fukakin_price,0)) AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_cmp               itc
                   ,ic_adjs_jnl               iaj
                   ,ic_jrnl_mst               ijm
                   ,ic_item_mst_b             iimb
                   ,xxpo_rcv_and_rtn_txns     xrrt
                   ,xxcmn_item_mst_b          ximb
                   ,gmi_item_categories       gic1
                   ,mtl_categories_b          mcb1
                   ,gmi_item_categories       gic2
                   ,mtl_categories_b          mcb2
                   ,mtl_categories_tl         mct2
                   ,gmi_item_categories       gic3
                   ,mtl_categories_b          mcb3
                   ,gmi_item_categories       gic4
                   ,mtl_categories_b          mcb4
                   ,xxcmn_vendors2_v          xvv
                   ,hr_locations_all          hl
                   ,xxcmn_locations_all       xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itc.doc_type        = cv_adji
             AND    itc.reason_code     = cv_x201
             AND    itc.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itc.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iaj.trans_type      = itc.doc_type
             AND    iaj.doc_id          = itc.doc_id
             AND    iaj.doc_line        = itc.doc_line
             AND    ijm.journal_id      = iaj.journal_id
             AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1)
             AND    iimb.item_id        = itc.item_id
             AND    ximb.item_id        = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
             AND    gic1.item_id        = itc.item_id
             AND    gic1.category_set_id = cn_prod_class_id
             AND    mcb1.category_id    = gic1.category_id
             AND    mcb1.segment1       = ir_param.prod_div
             AND    gic2.item_id        = itc.item_id
             AND    gic2.category_set_id = cn_item_class_id
             AND    mcb2.category_id    = gic2.category_id
             AND    mct2.category_id    = mcb2.category_id
             AND    mct2.language       = gv_ja
             AND    mcb2.segment1       = ir_param.item_div
             AND    gic3.item_id        = itc.item_id
             AND    gic3.category_set_id = cn_crowd_code_id
             AND    mcb3.category_id    = gic3.category_id
             AND    gic4.item_id        = itc.item_id
             AND    gic4.category_set_id = cn_acnt_crowd_id
             AND    mcb4.category_id    = gic4.category_id
             AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itc.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = xrrt.vendor_id
             AND    hl.location_code         = xrrt.department_code
             AND    hl.location_id           = xl.location_id
             and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itc.trans_date)
             and    xsupv.start_date_active <(TRUNC(itc.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itc.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id               = itc.item_id
            ) mst
      GROUP BY mst.result_post
              ,mst.location_name
              ,mst.item_div
              ,mst.item_div_name
              ,mst.segment1
              ,mst.vendor_name
              ,mst.crowd_code
              ,mst.item_code
              ,mst.item_s_name
              ,mst.item_um
              ,mst.item_atr15
              ,mst.lot_ctl
      ORDER BY mst.result_post
              ,mst.item_div
              ,mst.segment1
              ,mst.crowd_code
              ,mst.item_code
    ;
--yutsuzuk add
*/
-- 2008/10/14 v1.6 DELETE END
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;  -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2008/10/14 v1.6 ADD START
    -- ----------------------------------------------------
    -- SELECT�吶��
    -- ----------------------------------------------------
    lv_select := 'SELECT ';
-- 2008/12/12 v1.14 UPDATE START
/*
    -- ���ѕ���
    IF ( ir_param.result_post IS NULL ) THEN
      lv_select := lv_select
        || '       mst.result_post           AS result_post '
        || '      ,mst.location_name         AS location_name ';
    ELSE
      lv_select := lv_select
        || '       NULL                      AS result_post '
        || '      ,NULL                      AS location_name ';
    END IF;
--
    lv_select := lv_select
      || '      ,mst.item_div              AS item_div '
      || '      ,mst.item_div_name         AS item_div_name ';
--
    -- �d����
    IF ( ir_param.party_code IS NULL ) THEN
      lv_select := lv_select
        || '      ,mst.segment1              AS vendor_code '
        || '      ,mst.vendor_name           AS vendor_name ';
    ELSE
      lv_select := lv_select
        || '      ,NULL                      AS vendor_code '
        || '      ,NULL                      AS vendor_name ';
    END IF;
*/
    -- ���ѕ���
    lv_select := lv_select
      || '       mst.result_post             AS result_post '
      || '      ,mst.location_name           AS location_name ';
--
    lv_select := lv_select
      || '      ,mst.item_div                AS item_div '
      || '      ,mst.item_div_name           AS item_div_name ';
--
    -- �d����
    lv_select := lv_select
      || '      ,mst.segment1                AS vendor_code '
      || '      ,mst.vendor_name             AS vendor_name ';
-- 2008/12/12 v1.14 UPDATE END
--
    -- �Q���
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- �Q��
      lv_select := lv_select
        || '      ,mst.crowd_code            AS crowd_code';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- �o���Q��
      lv_select := lv_select
        || '      ,mst.acnt_crowd_code       AS crowd_code ';
    END IF;
--
    lv_select := lv_select
      || '      ,mst.item_code             AS item_code '
      || '      ,mst.item_s_name           AS item_s_name '
      || '      ,mst.item_um               AS item_um '
      || '      ,mst.item_atr15            AS item_atr15 '
      || '      ,mst.lot_ctl               AS lot_ctl '
      || '      ,SUM(mst.trans_qty)        AS trans_qty '
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '      ,SUM(mst.purchases_price)   / SUM(mst.trans_qty) AS purchases_price '
--      || '      ,SUM(mst.powder_price)      / SUM(mst.trans_qty) AS powder_price '
--      || '      ,SUM(mst.commission_price)  / SUM(mst.trans_qty) AS commission_price '
      || '      ,SUM(mst.purchases_price)  / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS purchases_price '
      || '      ,SUM(mst.powder_price)     / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS powder_price '
      || '      ,SUM(mst.commission_price) / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS commission_price '
-- 2008/10/28 H.Itou Mod End
-- 2008/12/05 v1.13 UPDATE START
--      || '      ,SUM(mst.commission_price * mst.trans_qty) AS c_amt '
      || '      ,SUM(mst.commission_price) AS c_amt '
-- 2008/12/05 v1.13 UPDATE END
      || '      ,SUM(mst.assessment)       AS assessment '
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '      ,SUM(mst.stnd_unit_price)   / SUM(mst.trans_qty) AS stnd_unit_price '
-- 2008/11/19 N.Yoshida mod start �ڍs�f�[�^���ؕs��Ή�
--      || '      ,SUM(mst.stnd_unit_price) / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS stnd_unit_price '
      || '      ,mst.stnd_unit_price       AS stnd_unit_price '
-- 2008/11/19 N.Yoshida mod end �ڍs�f�[�^���ؕs��Ή�
-- 2008/10/28 H.Itou Mod End
      || '      ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt '
--      || '      ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt '
--      || '      ,SUM(mst.purchases_price) AS s_amt '
      || '      ,SUM(mst.powder_price) AS s_amt '
-- 2008/12/05 v1.13 ADD START
      || '      ,SUM(ROUND((mst.commission_price * :para_lkup_code) /100)) AS commission_tax '
      || '      ,SUM( '
                -- �x�����z�����
      || '            ROUND(NVL(mst.powder_price, ''' || gn_zero || ''') * :para_lkup_code / 100)'
                -- ���K���z�����
      || '          - ROUND(NVL(mst.commission_price, ''' || gn_zero || ''')  * :para_lkup_code / 100) '
      || '           ) AS payment_tax '
-- 2008/12/05 v1.13 ADD END
      || '      ,:para_lkup_code              AS c_tax ';
--
    -- ----------------------------------------------------
    -- �w���֘A����
    -- ----------------------------------------------------
    lv_porc_po := 'FROM '
      || '      ( '
-- 2008/11/13 v1.8 UPDATE START
--      || '       SELECT /*+ leading(itp gic1 mcb1 rsl rt pha pla plla) use_nl(itp gic1 mcb1)*/ '
      || '       SELECT /*+ leading(itp xrpm gic1 mcb1 rsl rt pha pla plla) use_nl(itp xrpm gic1 mcb1)*/ '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/12/12 v1.14 UPDATE START
--      || '              pha.attribute10         AS result_post '
--      || '             ,mcb2.segment1           AS item_div '
      || '              mcb2.segment1           AS item_div '
-- 2008/12/12 v1.14 UPDATE END
      || '             ,mct2.description        AS item_div_name '
      || '             ,iimb.item_id            AS item_id '
      || '             ,iimb.item_no            AS item_code '
      || '             ,iimb.item_um            AS item_um '
      || '             ,ximb.item_short_name    AS item_s_name '
      || '             ,iimb.attribute15        AS item_atr15 '
      || '             ,iimb.lot_ctl            AS lot_ctl '
      || '             ,pha.vendor_id           AS vendor_id '
      || '             ,mcb3.segment1           AS crowd_code '
      || '             ,mcb4.segment1           AS acnt_crowd_code '
-- 2008/11/13 v1.8 UPDATE START
--      || '             ,itp.trans_qty           AS trans_qty '
--      || '             ,NVL(pla.unit_price, 0) * NVL(itp.trans_qty, 0) AS purchases_price '
      || '             ,NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div) AS trans_qty '
-- 2008/11/29 v1.10 UPDATE START
--      || '            ,ROUND(NVL(pla.unit_price, 0) '
      || '            ,ROUND(NVL(pla.attribute8, 0) '
      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS purchases_price '
-- 2008/11/13 v1.8 UPDATE END
--      || '             ,NVL(plla.attribute2, :para_zero) AS powder_price '
      || '            ,ROUND(NVL(pla.unit_price, :para_zero) '
      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS powder_price '
--      || '             ,NVL(plla.attribute4, :para_zero) AS commission_price '
-- 2008/12/06 MOD START
--      || '            ,ROUND(NVL(plla.attribute4, :para_zero) '
--      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS commission_price '
--      || '             ,NVL(plla.attribute7, :para_zero) AS assessment '
      || '            ,TO_NUMBER(NVL(plla.attribute5, :para_zero)) AS commission_price '
      || '            ,TO_NUMBER(NVL(plla.attribute8, :para_zero)) AS assessment '
-- 2008/12/06 MOD END
-- 2008/11/29 v1.10 UPDATE END
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '             ,(NVL((SELECT xsupv.stnd_unit_price '
--      || '                    FROM   xxcmn_stnd_unit_price_v xsupv '
--      || '                    WHERE  xsupv.start_date_active < (TRUNC(itp.trans_date) + 1) '
--      || '                    AND    ((xsupv.end_date_active >= TRUNC(itp.trans_date)) '
--      || '                             OR (xsupv.end_date_active IS NULL)) '
--      || '                    AND    xsupv.item_id = itp.item_id), 0)) AS stnd_unit_price '
-- 2008/12/12 v1.14 UPDATE START
--      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price '
-- 2008/10/28 H.Itou Mod End
--      || '             ,xvv.segment1            AS segment1 '
--      || '             ,xvv.vendor_short_name   AS vendor_name '
--      || '             ,xl.location_short_name  AS location_name '
      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price ';
    -- ���ѕ���
    IF ( ir_param.result_post IS NULL ) THEN
    lv_porc_po := lv_porc_po
      || '      ,pha.attribute10                AS result_post '
      || '      ,xl.location_short_name         AS location_name ';
    ELSE
    lv_porc_po := lv_porc_po
      || '      ,NULL                           AS result_post '
      || '      ,NULL                           AS location_name ';
    END IF;
    -- �d����
    IF ( ir_param.party_code IS NULL ) THEN
    lv_porc_po := lv_porc_po
      || '      ,xvv.segment1                   AS segment1 '
      || '      ,xvv.vendor_short_name          AS vendor_name ';
    ELSE
    lv_porc_po := lv_porc_po
      || '      ,NULL                           AS segment1 '
      || '      ,NULL                           AS vendor_name ';
    END IF;
    lv_porc_po := lv_porc_po
-- 2008/12/12 v1.14 UPDATE END
      || '       FROM   ic_tran_pnd              itp '
      || '             ,rcv_shipment_lines       rsl '
      || '             ,rcv_transactions         rt '
      || '             ,po_headers_all           pha '
      || '             ,po_lines_all             pla '
      || '             ,po_line_locations_all    plla '
      || '             ,ic_item_mst_b            iimb '
      || '             ,xxcmn_item_mst_b         ximb '
      || '             ,gmi_item_categories      gic1 '
      || '             ,mtl_categories_b         mcb1 '
      || '             ,gmi_item_categories      gic2 '
      || '             ,mtl_categories_b         mcb2 '
      || '             ,mtl_categories_tl        mct2 '
      || '             ,gmi_item_categories      gic3 '
      || '             ,mtl_categories_b         mcb3 '
      || '             ,gmi_item_categories      gic4 '
      || '             ,mtl_categories_b         mcb4 '
      || '             ,xxcmn_vendors2_v         xvv '
      || '             ,hr_locations_all         hl '
      || '             ,xxcmn_locations_all      xl '
-- 2008/10/28 H.Itou Add Start T_S_524�Ή�(�đΉ�)
      || '             ,xxcmn_stnd_unit_price_v  xsupv '
-- 2008/10/28 H.Itou Add End
-- 2008/11/13 v1.8 ADD START
      || '             ,xxcmn_rcv_pay_mst        xrpm '
-- 2008/11/13 v1.8 ADD END
      || '       WHERE  itp.doc_type                = :para_porc '
      || '       AND    itp.completed_ind           = :para_one '
      || '       AND    itp.trans_date '
      || '                >=FND_DATE.STRING_TO_DATE(:para_param_proc_from '
      || '                                         ,:para_char_yyyymm_format) '
      || '       AND    itp.trans_date '
      || '                < ADD_MONTHS( '
      || '                  FND_DATE.STRING_TO_DATE(:para_param_proc_to '
      || '                                         ,:para_char_yyyymm_format), 1) '
      || '       AND    iimb.item_id                = itp.item_id '
      || '       AND    ximb.item_id                = iimb.item_id '
      || '       AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1) '
      || '       AND    ximb.end_date_active   >= TRUNC(itp.trans_date) '
      || '       AND    gic1.item_id                = itp.item_id '
      || '       AND    gic1.category_set_id        = :para_prod_class_id '
      || '       AND    mcb1.category_id            = gic1.category_id '
      || '       AND    mcb1.segment1               = :para_param_prod_div '
      || '       AND    gic2.item_id                = itp.item_id '
      || '       AND    gic2.category_set_id        = :para_item_class_id '
      || '       AND    mcb2.category_id            = gic2.category_id '
      || '       AND    mct2.category_id            = mcb2.category_id '
      || '       AND    mct2.language               = :para_ja '
      || '       AND    gic3.item_id                = itp.item_id '
      || '       AND    gic3.category_set_id        = :para_crowd_code_id '
      || '       AND    mcb3.category_id            = gic3.category_id '
      || '       AND    gic4.item_id                = itp.item_id '
      || '       AND    gic4.category_set_id        = :para_acnt_crowd_id '
      || '       AND    mcb4.category_id            = gic4.category_id '
      || '       AND    rsl.shipment_header_id      = itp.doc_id '
      || '       AND    rsl.line_num                = itp.doc_line '
      || '       AND    rt.transaction_id           = itp.line_id '
      || '       AND    rt.shipment_line_id         = rsl.shipment_line_id '
      || '       AND    rsl.po_header_id            = pha.po_header_id '
      || '       AND    rsl.po_line_id              = pla.po_line_id '
      || '       AND    pla.po_line_id              = plla.po_line_id '
      || '       AND    rsl.source_document_code    = :para_po '
-- 2008/12/04 v1.14 UPDATE START
      || '       AND    rt.transaction_type         = xrpm.transaction_type'
--      || '       AND    rt.transaction_type     IN (:para_deliver '
--      || '                                         ,:para_return_to_vendor) '
-- 2008/12/04 v1.14 UPDATE END
      || '       AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1) '
      || '       AND    ((xvv.end_date_active >= TRUNC(itp.trans_date)) '
      || '              OR (xvv.end_date_active IS NULL)) '
      || '       AND    xvv.vendor_id               = pha.vendor_id '
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '       AND    hl.location_code            = pha.attribute10 '
--      || '       AND    hl.location_id              = xl.location_id '
--      || '       AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1) '
--      || '       AND ( '
--      || '             (xl.end_date_active >= TRUNC(itp.trans_date)) '
--      || '             OR '
--      || '             (xl.end_date_active IS NULL) '
--      || '           ) '
      || '       AND hl.location_code(+) = pha.attribute10 '
      || '       AND hl.location_id      = xl.location_id(+) '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itp.trans_date) + 1) '
--      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itp.trans_date) '
      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itp.trans_date) + 1) '
      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itp.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
      || '       AND xsupv.item_id(+)    = itp.item_id '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itp.trans_date) + 1) '
--      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itp.trans_date) '
      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itp.trans_date) + 1) '
      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itp.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/10/28 H.Itou Mod End
-- 2008/11/13 v1.8 ADD START
      || '       AND    xrpm.doc_type             = :para_porc '
      || '       AND    xrpm.source_document_code <> :para_rma '
      || '       AND    rsl.source_document_code  = xrpm.source_document_code '
      || '       AND    rt.transaction_type       = xrpm.transaction_type '
      || '       AND    xrpm.source_document_code = :para_po '
-- 2008/12/04 v1.14 DELETE START
--      || '       AND    xrpm.transaction_type IN (:para_deliver, :para_return_to_vendor) '
-- 2008/12/04 v1.14 DELETE END
      || '       AND    itp.doc_type              = xrpm.doc_type '
      || '       AND    xrpm.break_col_05         IS NOT NULL '
-- 2008/11/13 v1.8 ADD END
-- 2008/12/16 v1.15 ADD START
      || '       AND    pha.attribute1 >= :para_money_fix '
      || '       AND    pha.attribute1 <  :para_cancel '
-- 2008/12/16 v1.15 ADD END
      ;
--
    -- �i�ڋ敪
    IF ( ir_param.item_div IS NOT NULL ) THEN
      lv_porc_po := lv_porc_po
        || '       AND    mcb2.segment1               = ''' || ir_param.item_div || '''';
    END IF;
--
    -- ���ѕ���
    IF ( (ir_param.result_post IS NOT NULL)
      AND (ir_param.result_post <> xxcmn770015c.dept_code_all) ) THEN
      lv_porc_po := lv_porc_po
        || '       AND pha.attribute10 = ''' || ir_param.result_post || '''';
    END IF;
--
    -- �d����
    IF ( (ir_param.party_code IS NOT NULL)
      AND (ir_param.party_code <> xxcmn770015c.dept_code_all) ) THEN
      lv_porc_po := lv_porc_po
        || '       AND pha.vendor_id = ''' || gn_para_vendor_id || '''';
    END IF;
--
    -- �Q���
    IF ( (ir_param.crowd_type = cv_crowd_type)
      AND (ir_param.crowd_code IS NOT NULL) ) THEN
      -- �Q��
      lv_porc_po := lv_porc_po
        || '       AND mcb3.segment1 = ''' || ir_param.crowd_code || '''';
    ELSIF ( (ir_param.crowd_type = cv_crowd_type_acnt)
      AND (ir_param.acnt_crowd_code IS NOT NULL) ) THEN
      -- �o���Q��
      lv_porc_po := lv_porc_po
        || '       AND mcb4.segment1 = ''' || ir_param.acnt_crowd_code || '''';
    END IF;
--
    -- ----------------------------------------------------
    -- �݌ɒ���(�d����ԕi)����
    -- ----------------------------------------------------
    lv_adji := 'UNION ALL '
-- 2008/11/13 v1.8 UPDATE START
--      || '       SELECT /*+ leading(itc gic1 mcb1 iaj ijm xrrt ) use_nl(itc gic1 mcb1) */ '
      || '       SELECT /*+ leading(itc xrpm gic1 mcb1 iaj ijm xrrt ) use_nl(itc xrpm gic1 mcb1) */ '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/12/12 v1.14 UPDATE START
--      || '              xrrt.department_code    AS result_post '
--      || '             ,mcb2.segment1           AS item_div '
      || '              mcb2.segment1           AS item_div '
-- 2008/12/12 v1.14 UPDATE END
      || '             ,mct2.description        AS item_div_name '
      || '             ,iimb.item_id            AS item_id '
      || '             ,iimb.item_no            AS item_code '
      || '             ,iimb.item_um            AS item_um '
      || '             ,ximb.item_short_name    AS item_s_name '
      || '             ,iimb.attribute15        AS item_atr15 '
      || '             ,iimb.lot_ctl            AS lot_ctl '
      || '             ,xrrt.vendor_id          AS vendor_id '
      || '             ,mcb3.segment1           AS crowd_code '
      || '             ,mcb4.segment1           AS acnt_crowd_code '
-- 2008/11/13 v1.8 UPDATE START
--      || '             ,itc.trans_qty           AS trans_qty '
--      || '             ,NVL(xrrt.unit_price, 0) '
--      || '                * NVL(itc.trans_qty, 0) AS purchases_price '
      || '             ,NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)) AS trans_qty '
      || '      ,ROUND(NVL(xrrt.unit_price, 0) '
      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS purchases_price '
-- 2008/11/13 v1.8 UPDATE START
-- 2008/11/29 v1.10 UPDATE START
--      || '             ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price, :para_zero)) AS powder_price '
      || '      ,ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS powder_price '
--      || '           ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price, :para_zero)) AS commission_price '
      || '      ,ROUND(NVL(xrrt.kousen_rate_or_unit_price, :para_zero) '
      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS commission_price '
      || '             ,NVL(xrrt.fukakin_price, :para_zero) AS assessment '
-- 2008/11/29 v1.10 UPDATE END
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '             ,(NVL((SELECT xsupv.stnd_unit_price '
--      || '                    FROM   xxcmn_stnd_unit_price_v xsupv '
--      || '                    WHERE  xsupv.start_date_active < (TRUNC(itc.trans_date) + 1) '
--      || '                    AND    ((xsupv.end_date_active >= TRUNC(itc.trans_date)) '
--      || '                             OR (xsupv.end_date_active IS NULL)) '
--      || '                    AND    xsupv.item_id = itc.item_id), 0)) AS stnd_unit_price '
-- 2008/12/12 v1.14 UPDATE START
--      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price '
-- 2008/10/28 H.Itou Mod End
--      || '             ,xvv.segment1            AS segment1 '
--      || '             ,xvv.vendor_short_name   AS vendor_name '
--      || '             ,xl.location_short_name  AS location_name '
      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price ';
    -- ���ѕ���
    IF ( ir_param.result_post IS NULL ) THEN
    lv_adji := lv_adji
      || '      ,xrrt.department_code                AS result_post '
      || '      ,xl.location_short_name              AS location_name ';
    ELSE
    lv_adji := lv_adji
      || '      ,NULL                                AS result_post '
      || '      ,NULL                                AS location_name ';
    END IF;
    -- �d����
    IF ( ir_param.party_code IS NULL ) THEN
    lv_adji := lv_adji
      || '      ,xvv.segment1                        AS segment1 '
      || '      ,xvv.vendor_short_name               AS vendor_name ';
    ELSE
    lv_adji := lv_adji
      || '      ,NULL                                AS segment1 '
      || '      ,NULL                                AS vendor_name ';
    END IF;
    lv_adji := lv_adji
-- 2008/12/12 v1.14 UPDATE END
      || '       FROM   ic_tran_cmp               itc '
      || '             ,ic_adjs_jnl               iaj '
      || '             ,ic_jrnl_mst               ijm '
      || '             ,ic_item_mst_b             iimb '
      || '             ,xxpo_rcv_and_rtn_txns     xrrt '
      || '             ,xxcmn_item_mst_b          ximb '
      || '             ,gmi_item_categories       gic1 '
      || '             ,mtl_categories_b          mcb1 '
      || '             ,gmi_item_categories       gic2 '
      || '             ,mtl_categories_b          mcb2 '
      || '             ,mtl_categories_tl         mct2 '
      || '             ,gmi_item_categories       gic3 '
      || '             ,mtl_categories_b          mcb3 '
      || '             ,gmi_item_categories       gic4 '
      || '             ,mtl_categories_b          mcb4 '
      || '             ,xxcmn_vendors2_v          xvv '
      || '             ,hr_locations_all          hl '
      || '             ,xxcmn_locations_all       xl '
-- 2008/10/28 H.Itou Add Start T_S_524�Ή�(�đΉ�)
      || '             ,xxcmn_stnd_unit_price_v  xsupv '
-- 2008/10/28 H.Itou Add End
-- 2008/11/13 v1.8 ADD START
      || '             ,xxcmn_rcv_pay_mst        xrpm '
-- 2008/11/13 v1.8 ADD END
      || '       WHERE  itc.doc_type        = :para_adji '
      || '       AND    itc.reason_code     = :para_x201 '
      || '       AND    itc.trans_date '
      || '                >= FND_DATE.STRING_TO_DATE(:para_param_proc_from '
      || '                                          ,:para_char_yyyymm_format) '
      || '       AND    itc.trans_date '
      || '                < ADD_MONTHS( '
      || '                  FND_DATE.STRING_TO_DATE(:para_param_proc_to '
      || '                                         ,:para_char_yyyymm_format), 1) '
      || '       AND    iaj.trans_type      = itc.doc_type '
      || '       AND    iaj.doc_id          = itc.doc_id '
      || '       AND    iaj.doc_line        = itc.doc_line '
      || '       AND    ijm.journal_id      = iaj.journal_id '
      || '       AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1) '
      || '       AND    iimb.item_id        = itc.item_id '
      || '       AND    ximb.item_id        = iimb.item_id '
      || '       AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1) '
      || '       AND    ximb.end_date_active   >= TRUNC(itc.trans_date) '
      || '       AND    gic1.item_id        = itc.item_id '
      || '       AND    gic1.category_set_id = :para_prod_class_id '
      || '       AND    mcb1.category_id    = gic1.category_id '
      || '       AND    mcb1.segment1       = :para_param_prod_div '
      || '       AND    gic2.item_id        = itc.item_id '
      || '       AND    gic2.category_set_id = :para_item_class_id '
      || '       AND    mcb2.category_id    = gic2.category_id '
      || '       AND    mct2.category_id    = mcb2.category_id '
      || '       AND    mct2.language       = :para_ja '
      || '       AND    gic3.item_id        = itc.item_id '
      || '       AND    gic3.category_set_id = :para_crowd_code_id '
      || '       AND    mcb3.category_id    = gic3.category_id '
      || '       AND    gic4.item_id        = itc.item_id '
      || '       AND    gic4.category_set_id = :para_acnt_crowd_id '
      || '       AND    mcb4.category_id    = gic4.category_id '
      || '       AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1) '
      || '       AND    ((xvv.end_date_active >= TRUNC(itc.trans_date)) '
      || '              OR (xvv.end_date_active IS NULL)) '
      || '       AND    xvv.vendor_id     = xrrt.vendor_id '
-- 2008/10/28 H.Itou Mod Start T_S_524�Ή�(�đΉ�)
--      || '       AND    hl.location_code         = xrrt.department_code '
--      || '       AND    hl.location_id           = xl.location_id '
--      || '       and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1) '
--      || '       AND ( '
--      || '             (xl.end_date_active >= TRUNC(itc.trans_date)) '
--      || '             OR '
--      || '             (xl.end_date_active IS NULL) '
--      || '           ) '
      || '       AND hl.location_code(+) = xrrt.department_code '
      || '       AND hl.location_id      = xl.location_id(+) '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itc.trans_date) + 1) '
--      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itc.trans_date) '
      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itc.trans_date) + 1) '
      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itc.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
      || '       AND xsupv.item_id(+)    = itc.item_id '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itc.trans_date) + 1) '
--      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itc.trans_date) '
      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itc.trans_date) + 1) '
      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itc.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/10/28 H.Itou Mod End
-- 2008/11/13 v1.8 ADD START
      || '       AND    xrpm.doc_type             = :para_adji '
      || '       AND    itc.doc_type              = xrpm.doc_type '
      || '       AND    itc.reason_code           = xrpm.reason_code '
      || '       AND    xrpm.break_col_05         IS NOT NULL '
-- 2008/11/13 v1.8 ADD END
      ;
--
    -- �i�ڋ敪
    IF ( ir_param.item_div IS NOT NULL ) THEN
      lv_adji := lv_adji
        || '       AND    mcb2.segment1               = ''' || ir_param.item_div || '''';
    END IF;
--
    -- ���ѕ���
    IF ( (ir_param.result_post IS NOT NULL)
      AND (ir_param.result_post <> xxcmn770015c.dept_code_all) ) THEN
      lv_adji := lv_adji
        || '       AND xrrt.department_code = ''' || ir_param.result_post || '''';
    END IF;
--
    -- �d����
    IF ( (ir_param.party_code IS NOT NULL)
      AND (ir_param.party_code <> xxcmn770015c.dept_code_all) ) THEN
      lv_adji := lv_adji
        || '       AND xrrt.vendor_id = ''' || gn_para_vendor_id || '''';
    END IF;
--
    -- �Q���
    IF ( (ir_param.crowd_type = cv_crowd_type)
      AND (ir_param.crowd_code IS NOT NULL) ) THEN
      -- �Q��
      lv_adji := lv_adji
        || '       AND mcb3.segment1 = ''' || ir_param.crowd_code || '''';
    ELSIF ( (ir_param.crowd_type = cv_crowd_type_acnt)
      AND (ir_param.acnt_crowd_code IS NOT NULL) ) THEN
      -- �o���Q��
      lv_adji := lv_adji
        || '       AND mcb4.segment1 = ''' || ir_param.acnt_crowd_code || '''';
    END IF;
--
    lv_adji := lv_adji
      || '      ) mst ';
--
    -- ----------------------------------------------------
    -- GROUP�吶��
    -- ----------------------------------------------------
    lv_group := 'GROUP BY '
      || '         mst.result_post '
      || '        ,mst.location_name '
      || '        ,mst.item_div '
      || '        ,mst.item_div_name '
      || '        ,mst.segment1 '
      || '        ,mst.vendor_name ';
--
    -- �Q���
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- �Q��
      lv_group := lv_group
        || '        ,mst.crowd_code ';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- �o���Q��
      lv_group := lv_group
        || '        ,mst.acnt_crowd_code ';
    END IF;
--
    lv_group := lv_group
      || '        ,mst.item_code '
      || '        ,mst.item_s_name '
      || '        ,mst.item_um '
      || '        ,mst.item_atr15 '
      || '        ,mst.lot_ctl '
-- 2008/11/19 N.Yoshida mod start �ڍs�f�[�^���ؕs��Ή�
      || '        ,mst.stnd_unit_price ';
-- 2008/11/19 N.Yoshida mod end �ڍs�f�[�^���ؕs��Ή�
--
    -- ----------------------------------------------------
    -- ORDER�吶��
    -- ----------------------------------------------------
    lv_order := 'ORDER BY ';
    -- ���ѕ���
    IF ( ir_param.result_post IS NULL ) THEN
      lv_order := lv_order
        || '         mst.result_post '
        || '        ,mst.item_div ';
    ELSE
      lv_order := lv_order
        || '         mst.item_div ';
    END IF;
    -- �d����
    IF ( ir_param.party_code IS NULL ) THEN
      lv_order := lv_order
        || '        ,mst.segment1 ';
    END IF;
    -- �Q���
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- �Q��
      lv_order := lv_order
        || '        ,mst.crowd_code ';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- �o���Q��
      lv_order := lv_order
        || '        ,mst.acnt_crowd_code ';
    END IF;
    lv_order := lv_order
      || '        ,mst.item_code ';
--
-- 2008/10/14 v1.6 ADD END
--yutsuzuk add
    SELECT flv.lookup_code
    INTO   lt_lkup_code
    FROM   xxcmn_lookup_values_v flv
    WHERE  flv.lookup_type = gv_xxcmn_ctr
    AND    ROWNUM          = 1;
--yutsuzuk add
-- 2008/10/14 v1.6 UPDATE START
/*
--yutsuzuk add
    IF  ( ir_param.result_post IS NULL )        -- ���ѕ���������
    AND ( ir_param.party_code IS NULL )         -- �d���斢����
    AND ( ir_param.crowd_type = cv_crowd_type ) -- �Q��
    AND ( ir_param.prod_div IS NOT NULL )       -- ���i�敪����
    THEN
      IF ( ir_param.item_div IS NULL )           -- �i�ڋ敪����
      THEN
        OPEN  get_cur01;
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec;
        CLOSE get_cur01;
      ELSE
        OPEN  get_cur02;
        FETCH get_cur02 BULK COLLECT INTO ot_data_rec;
        CLOSE get_cur02;
      END IF;
    END IF;
--yutsuzuk add
*/
    OPEN  lc_ref FOR lv_select
                  || lv_porc_po
                  || lv_adji
                  || lv_group
                  || lv_order   USING  lt_lkup_code
-- 2008/12/05 ADD START
                                      ,lt_lkup_code
                                      ,lt_lkup_code
                                      ,lt_lkup_code
-- 2008/12/05 ADD END
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_porc
                                      ,gn_one
                                      ,ir_param.proc_from
                                      ,gc_char_yyyymm_format
                                      ,ir_param.proc_to
                                      ,gc_char_yyyymm_format
                                      ,cn_prod_class_id
                                      ,ir_param.prod_div
                                      ,cn_item_class_id
                                      ,gv_ja
                                      ,cn_crowd_code_id
                                      ,cn_acnt_crowd_id
                                      ,cv_po
-- 2008/12/04 v1.14 UPDATE START
--                                      ,cv_deliver
--                                      ,cv_return_to_vendor
-- 2008/12/04 v1.14 UPDATE END
-- 2008/11/13 v1.8 ADD START
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,cv_porc
                                      ,cv_rma
                                      ,cv_po
-- 2008/12/16 v1.15 ADD START
                                      ,cv_money_fix
                                      ,cv_cancel
-- 2008/12/16 v1.15 ADD END
-- 2008/12/04 v1.14 UPDATE START
--                                      ,cv_deliver
--                                      ,cv_return_to_vendor
-- 2008/12/04 v1.14 UPDATE END
-- 2008/11/13 v1.8 ADD END
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_adji
                                      ,cv_x201
                                      ,ir_param.proc_from
                                      ,gc_char_yyyymm_format
                                      ,ir_param.proc_to
                                      ,gc_char_yyyymm_format
                                      ,cn_prod_class_id
                                      ,ir_param.prod_div
                                      ,cn_item_class_id
                                      ,gv_ja
                                      ,cn_crowd_code_id
-- 2008/11/13 v1.8 UPDATE START
--                                      ,cn_acnt_crowd_id;
                                      ,cn_acnt_crowd_id
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,cv_adji
                                      ;
-- 2008/11/13 v1.8 UPDATE END
--
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    CLOSE lc_ref;
-- 2008/10/14 v1.6 UPDATE END
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF lc_ref%ISOPEN THEN
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_line
   * Description      : �w�l�k�f�[�^�쐬(����)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_line(
      ov_errbuf                    OUT VARCHAR2          -- �װ�ү����
     ,ov_retcode                   OUT VARCHAR2          -- ���ݥ����
     ,ov_errmsg                    OUT VARCHAR2          -- հ�ް��װ�ү����
     ,ir_param                     IN  rec_param_data    -- ���Ұ�
     ,it_data_rec                  IN  rec_data_type_dtl -- �擾ں���
     ,in_i                         IN  NUMBER            -- �A��
     ,iot_xml_idx                  IN OUT NUMBER         -- �w�l�k�ް���ޕ\�̲��ޯ��
     ,iot_xml_data_table           IN OUT XML_DATA       -- XML�ް�
     ,on_sum_quantity              IN OUT NUMBER         -- ���ʌv
     ,on_sum_order_amount          IN OUT NUMBER         -- �d�����z�v
     ,on_sum_commission_price      IN OUT NUMBER         -- ���K�v
     ,on_sum_commission_tax_amount IN OUT NUMBER         -- ����Ōv(���K)
     ,on_sum_commission_amount     IN OUT NUMBER         -- ���K���z
     ,on_sum_assess_amount         IN OUT NUMBER         -- ���ۋ��v
     ,on_sum_payment               IN OUT NUMBER         -- �x���v
     ,on_sum_payment_amount_tax    IN OUT NUMBER         -- ����Ōv(�x��)
     ,on_sum_payment_amount        IN OUT NUMBER         -- �x�����z�v
     ,on_sum_standard_amount       IN OUT NUMBER         -- �W�����z�v
     ,on_sum_difference_amount     IN OUT NUMBER         -- ���ٌv
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_line' ; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_qty                   NUMBER; -- ����
    ln_order_price           NUMBER; -- �d���P��
    ln_order_amount          NUMBER; -- �d�����z
    ln_commission_tax_amount NUMBER; -- ����œ�(���K)
    ln_commission_amount     NUMBER; -- ���K���z
    ln_payment               NUMBER; -- �x��
    ln_payment_amount_tax    NUMBER; -- ����œ�(�x��)
    ln_payment_amount        NUMBER; -- �x�����z
    ln_standard_amount       NUMBER; -- �W�����z
    ln_difference_amount     NUMBER; -- ����
    ln_tax                   NUMBER; -- �����
--
  BEGIN
--
    -- =====================================================
    -- ���׃f�[�^�o��
    -- =====================================================
    -- ���׃N���A
    ln_qty                   := 0; -- ����
    ln_order_price           := 0; -- �d���P��
    ln_order_amount          := 0; -- �d�����z
    ln_commission_tax_amount := 0; -- ����œ�(���K)
    ln_commission_amount     := 0; -- ���K���z
    ln_payment               := 0; -- �x��
    ln_payment_amount_tax    := 0; -- ����œ�(�x��)
    ln_payment_amount        := 0; -- �x�����z
    ln_standard_amount       := 0; -- �W�����z
    ln_difference_amount     := 0; -- ����
    -- ����ŌW��
    ln_tax := TO_NUMBER(NVL(it_data_rec.c_tax,gn_zero)) / gn_100;
    -- -----------------------------------------------------
    -- �i�ڂk�f�J�n�^�O�o��
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �i�ڂf�J�n�^�O�o��
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪�R�[�h
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_code' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.item_code;
    -- �i�ڋ敪����
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_name' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value :=
      SUBSTRB(it_data_rec.item_name,gn_one,gn_20) ;
    -- �P��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'uom_code' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.item_um;
    -- ����
    ln_qty := it_data_rec.trans_qty;
    IF ( ln_qty IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'quantity' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_qty;
      on_sum_quantity := on_sum_quantity + ln_qty;
    END IF;
    -- �d���P��
-- 2008/11/29 v1.10 UPDATE START
    /*IF ( it_data_rec.item_atr15 = gc_cost_st ) THEN
      -- �i��.�����Ǘ��敪 = 1:�W������ (�W�������}�X�^���A���ےP��)
      ln_order_price := it_data_rec.stnd_unit_price; -- �W���P��
    ELSE
      -- �i��.�����Ǘ��敪 = 0:���ی���
      IF ( it_data_rec.lot_ctl = gn_lot_yes ) THEN
        -- �i��.���b�g�Ǘ� = 1:�Ώ� (���b�g�ʌ����e�[�u�����A���ےP��)
        ln_order_price := it_data_rec.purchases_price; -- �d���P��(���b�g)�����d����
      ELSE
        -- �i��.���b�g�Ǘ� = 0:�ΏۊO (�W�������}�X�^���A���ےP��)
        ln_order_price := it_data_rec.stnd_unit_price; -- �W���P��
      END IF;
    END IF;*/
    ln_order_price := it_data_rec.purchases_price; -- �d���P��(���b�g)�����d����
-- 2008/11/29 v1.10 UPDATE END
    IF ( ln_order_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'order_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ROUND(ln_order_price,gn_2);
    END IF;
    -- ������P��
    IF ( it_data_rec.powder_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'konahiki_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.powder_price;
    END IF;
-- 2008/11/29 v1.10 UPDATE START
    -- �d�����z
    /*IF ( it_data_rec.item_atr15 = gc_cost_st ) THEN
      -- �i��.�����Ǘ��敪 = 1:�W������ (�W�������}�X�^���A���ےP��)
      ln_order_amount := ROUND(it_data_rec.j_amt); -- �W���P�� * ����
    ELSE
      -- �i��.�����Ǘ��敪 = 0:���ی���
      IF ( it_data_rec.lot_ctl = gn_lot_yes ) THEN
        -- �i��.���b�g�Ǘ� = 1:�Ώ� (���b�g�ʌ����e�[�u�����A���ےP��)
        ln_order_amount := ROUND(it_data_rec.s_amt); -- �d���P��(ۯ�) * ����
      ELSE
        -- �i��.���b�g�Ǘ� = 0:�ΏۊO (�W�������}�X�^���A���ےP��)
        ln_order_amount := ROUND(it_data_rec.j_amt); -- �W���P�� * ����
      END IF;
    END IF;*/
    ln_order_amount := ROUND(it_data_rec.s_amt); -- �d���P��(ۯ�) * ����
-- 2008/11/29 v1.10 UPDATE END
    IF ( ln_order_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'order_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_order_amount;
      on_sum_order_amount := on_sum_order_amount + ln_order_amount;
    END IF;
    -- ���K
    IF ( it_data_rec.commission_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ROUND(it_data_rec.c_amt);
      on_sum_commission_price := on_sum_commission_price + ROUND(it_data_rec.c_amt);
    END IF;
    -- ����œ�(���K)
-- 2008/12/05 v1.13 UPDATE START
--    ln_commission_tax_amount := ROUND(it_data_rec.c_amt * ln_tax);
    ln_commission_tax_amount := it_data_rec.commission_tax;
-- 2008/12/05 v1.13 UPDATE END
    IF ( ln_commission_tax_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_tax_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_commission_tax_amount;
      on_sum_commission_tax_amount :=
        on_sum_commission_tax_amount + ln_commission_tax_amount;
    END IF;
    -- ���K���z
    ln_commission_amount := ROUND(it_data_rec.c_amt) + ln_commission_tax_amount;
    IF ( ln_commission_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_commission_amount;
      on_sum_commission_amount := on_sum_commission_amount + ln_commission_amount;
    END IF;
    -- ���ۋ�
    IF ( it_data_rec.assessment IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'assess_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.assessment;
      on_sum_assess_amount := on_sum_assess_amount + it_data_rec.assessment;
    END IF;
    -- �x��
    ln_payment :=
      ln_order_amount - NVL(ROUND(it_data_rec.c_amt),gn_zero) - NVL(it_data_rec.assessment,gn_zero);
    IF ( ln_payment IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment;
      on_sum_payment := on_sum_payment + ln_payment;
    END IF;
    -- ����œ�(�x��)
-- 2008/12/05 v1.13 UPDATE START
--    ln_payment_amount_tax := ROUND(ln_payment * ln_tax);
    ln_payment_amount_tax := it_data_rec.payment_tax;
-- 2008/12/05 v1.13 UPDATE END
    IF ( ln_payment_amount_tax IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment_amount_tax' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment_amount_tax;
      on_sum_payment_amount_tax :=
        on_sum_payment_amount_tax + ln_payment_amount_tax;
    END IF;
    -- �x�����z
-- 2008/12/05 v1.12 UPDATE START
--    ln_payment_amount := ln_payment + ln_payment_amount_tax;
    ln_payment_amount := NVL(ln_payment,gn_zero) + NVL(ln_payment_amount_tax,gn_zero);
-- 2008/12/05 v1.12 UPDATE END
    IF ( ln_payment_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment_amount;
      on_sum_payment_amount := on_sum_payment_amount + ln_payment_amount;
    END IF;
    -- �W���P��
    IF ( it_data_rec.stnd_unit_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'standard_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.stnd_unit_price;
    END IF;
    -- �W�����z
    ln_standard_amount := ROUND(it_data_rec.stnd_unit_price * ln_qty);
    IF ( ln_standard_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'standard_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_standard_amount;
      on_sum_standard_amount := on_sum_standard_amount + ln_standard_amount;
    END IF;
    -- ����
    ln_difference_amount := NVL(ln_order_amount,gn_zero) - NVL(ln_standard_amount,gn_zero);
    IF ( ln_difference_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'difference_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_difference_amount;
      on_sum_difference_amount := on_sum_difference_amount + ln_difference_amount;
    END IF;
    -- �i�ژA��
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_position' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_i;
    -- -----------------------------------------------------
    -- �i�ڂf�I���^�O�o��
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �i�ڂk�f�I���^�O�o��
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data_line ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data    -- �p�����[�^
     ,it_data_rec       IN  tab_data_type_dtl -- �擾���R�[�h�Q
     ,ot_xml_data_table OUT XML_DATA          -- XML�f�[�^
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
    lc_break_init      VARCHAR2(100) DEFAULT '*' ;    -- �����l
    lc_break_null      VARCHAR2(100) DEFAULT '****' ; -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_result_post  xxcmn_rcv_pay_mst_porc_po_v.result_post%TYPE; -- ���ѕ���
    lv_item_div     xxcmn_lot_each_item_v.item_div%TYPE;       -- �i�ڋ敪
    lv_vendor_code  xxcmn_vendors2_v.segment1%TYPE;            -- �d����ID
    lv_crowd_code   xxcmn_lot_each_item_v.crowd_code%TYPE;     -- �ڌQ����or�o���ڌQ����
    lv_crowd_code_l xxcmn_lot_each_item_v.crowd_code%TYPE;     -- ��Q����or�o����Q����
    lv_crowd_code_m xxcmn_lot_each_item_v.crowd_code%TYPE;     -- ���Q����or�o�����Q����
    lv_crowd_code_s xxcmn_lot_each_item_v.crowd_code%TYPE;     -- ���Q����or�o�����Q����
--
    -- ���v�p
    ln_sum_quantity              NUMBER DEFAULT 0; -- ���ʌv
    ln_sum_order_amount          NUMBER DEFAULT 0; -- �d�����z�v
    ln_sum_commission_price      NUMBER DEFAULT 0; -- ���K�v
    ln_sum_commission_tax_amount NUMBER DEFAULT 0; -- ����Ōv(���K)
    ln_sum_commission_amount     NUMBER DEFAULT 0; -- ���K���z
    ln_sum_assess_amount         NUMBER DEFAULT 0; -- ���ۋ��v
    ln_sum_payment               NUMBER DEFAULT 0; -- �x���v
    ln_sum_payment_amount_tax    NUMBER DEFAULT 0; -- ����Ōv(�x��)
    ln_sum_payment_amount        NUMBER DEFAULT 0; -- �x�����z�v
    ln_sum_standard_amount       NUMBER DEFAULT 0; -- �W�������v
    ln_sum_difference_amount     NUMBER DEFAULT 0; -- ���ٌv
--
    lt_xml_idx         NUMBER DEFAULT 0; -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
    ld_proc_from       DATE;             -- �����N��(�J�n)
    ld_proc_to         DATE;             -- �����N��(�I��)
    ln_i               PLS_INTEGER;      -- IDX
--
    -- *** ���[�J���E��O���� ***
    no_data_expt       EXCEPTION ;       -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[G�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[G�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[�h�c
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_id' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := gv_report_id ;
    -- ���{��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'exec_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- �S������
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'charge_dept' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_user_dept,gn_one,gn_10) ;
    -- �S����
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'agent' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_user_name,gn_one,gn_14) ;
    -- �����N��(��)
    ld_proc_from := FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format);
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'process_year_month_from' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value :=
      TO_CHAR(ld_proc_from,gc_char_yyyy_format) || gv_ja_year ||
      TO_CHAR(ld_proc_from,gc_char_mm_format) || gv_ja_month;
    -- �����N��(��)
    ld_proc_to := FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format);
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'process_year_month_to' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value :=
      TO_CHAR(ld_proc_to,gc_char_yyyy_format) || gv_ja_year ||
      TO_CHAR(ld_proc_to,gc_char_mm_format) || gv_ja_month;
    -- ���i�敪�R�[�h
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'arti_div_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.prod_div;
    -- ���i�敪����
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'arti_div_name' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_prod_div_name,gn_one,gn_20);
    -- �i�ڋ敪�R�[�h
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.item_div;
    -- �i�ڋ敪����
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_item_div_name,gn_one,gn_20);
    -- �Q��ʃR�[�h
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_div' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.crowd_type;
    -- �Q��ʖ���
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_div_name' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_crowd_type,gn_one,gn_20);
    -- ���ѕ����R�[�h
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.result_post;
    -- ���ѕ�������
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_result_post_name,gn_one,gn_20);
    -- �d����R�[�h
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.party_code;
    -- �d���於��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_party_code_name,gn_one,gn_20);
    -- -----------------------------------------------------
    -- ���[�U�[G�I���^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �f�[�^LG�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- -----------------------------------------------------
      -- ���ѕ���LG�J�n�^�O�o��
      -- -----------------------------------------------------
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_result_post' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    END IF;
--
    -- �����m�F
    IF (it_data_rec.COUNT = gn_zero) THEN
      -- 0�����[�pXML�o��
      prc_create_xml_data_zero(
        ov_errbuf          => lv_errbuf             -- �װ�ү����
       ,ov_retcode         => lv_retcode            -- ���ݥ����
       ,ov_errmsg          => lv_errmsg             -- հ�ް��װ�ү����
       ,ir_param           => ir_param              -- �p�����[�^
       ,iot_xml_idx        => lt_xml_idx            -- XML�ް���ޕ\�̲��ޯ��
       ,iot_xml_data_table => ot_xml_data_table);   -- XML�ް�
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    ln_i := 1;
--
    <<main_data_loop>>
    WHILE ( ln_i <= it_data_rec.COUNT ) LOOP
--
      -- =====================================================
      -- ���ѕ���
      -- =====================================================
      lv_result_post := NVL(it_data_rec(ln_i).result_post,lc_break_null);
      IF ( ir_param.result_post IS NULL ) THEN
        -- ���ѕ���G�J�n�^�O
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_result_post' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        -- ���ѕ����R�[�h
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).result_post,gn_one,gn_15) ;
        -- ���ѕ�������
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).location_name,gn_one,gn_10) ;
      END IF;
      -- �i�ڋ敪LG�J�n�^�O�o��
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_article_div' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
      <<result_post_loop>>
      WHILE
        (
             (ln_i <= it_data_rec.COUNT)
         AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
        ) LOOP -- ���ѕ������[�v
--
        -- =====================================================
        -- �i�ڋ敪
        -- =====================================================
        lv_item_div := NVL(it_data_rec(ln_i).item_div,lc_break_null);
        -- �i�ڋ敪G�J�n�^�O�o��
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_article_div' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        -- �i�ڋ敪�R�[�h
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(ln_i).item_div;
        -- �i�ڋ敪����
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).item_div_name,gn_one,gn_10) ;
        IF ( ir_param.party_code IS NULL ) THEN
          -- �d����LG�J�n�^�O�o��
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_vendor' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF;
--
        <<item_div_loop>>
        WHILE
          (
               (ln_i          <= it_data_rec.COUNT)
           AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
           AND (lv_item_div    = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
          ) LOOP -- �i�ڋ敪���[�v
--
          -- =====================================================
          -- �d����
          -- =====================================================
          lv_vendor_code := NVL(it_data_rec(ln_i).vendor_code,lc_break_null);
          IF ( ir_param.party_code IS NULL ) THEN
            -- �d����G�J�n�^�O�o��
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_vendor' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- �d����R�[�h
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_code' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(ln_i).vendor_code;
            -- �d���於��
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_name' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value :=
              SUBSTRB(it_data_rec(ln_i).vendor_name,gn_one,gn_10) ;
          END IF;
          -- ��QLG�J�n�^�O�o��
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_l' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
          <<vendor_loop>>
          WHILE
            (
                 (ln_i <= it_data_rec.COUNT)
             AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
             AND (lv_item_div    = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
             AND (lv_vendor_code = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
            ) LOOP -- �d���惋�[�v
            -- -----------------------------------------------------
            -- ��Q�R�[�h
            -- -----------------------------------------------------
            lv_crowd_code_l := SUBSTR(
              NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_one);
            -- ��QG�J�n�^�O�o��
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_l' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- ��Q�R�[�h
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_lcode' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value :=
              SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_one);
            -- ���QLG�J�n�^�O�o��
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_m' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            <<crowd_l_loop>>
            WHILE
              (    (ln_i <= it_data_rec.COUNT)
               AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
               AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
               AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
               AND (lv_crowd_code_l =
                 SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_one))
              ) LOOP -- ��Q���[�v
              -- -----------------------------------------------------
              -- ���Q�R�[�h
              -- -----------------------------------------------------
              lv_crowd_code_m := SUBSTR(
                NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_2);
              -- ���QG�J�n�^�O�o��
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_m' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
              -- ���Q�R�[�h
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_mcode' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
              ot_xml_data_table(lt_xml_idx).tag_value :=
                SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_2);
              -- ���QLG�J�n�^�O�o��
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_s' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
              <<crowd_m_loop>>
              WHILE
                (
                     (ln_i <= it_data_rec.COUNT)
                 AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                 AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                 AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                 AND (lv_crowd_code_m =
                   SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_2))
                ) LOOP -- ���Q���[�v
--
                -- -----------------------------------------------------
                -- ���Q�R�[�h
                -- -----------------------------------------------------
                lv_crowd_code_s := SUBSTR(
                  NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_3);
                -- ���Q�f�J�n�^�O�o��
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_s' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                -- ���Q�R�[�h
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_scode' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
                ot_xml_data_table(lt_xml_idx).tag_value :=
                  SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_3);
                -- �ڌQ�R�[�hLG�J�n�^�O
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
                <<crowd_s_loop>>
                WHILE
                  (
                       (ln_i <= it_data_rec.COUNT)
                   AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                   AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                   AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                   AND (lv_crowd_code_s =
                     SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_3))
                  ) LOOP -- ���Q���[�v
--
                  -- -----------------------------------------------------
                  -- �ڌQ�R�[�h
                  -- -----------------------------------------------------
                  lv_crowd_code   := NVL(it_data_rec(ln_i).crowd_code,lc_break_null);
                  -- �ڌQ�R�[�hG�J�n�^�O
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                  -- �ڌQ�R�[�h
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_code' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
                  ot_xml_data_table(lt_xml_idx).tag_value :=
                    SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_4);
--
                  <<crowd_loop>>
                  WHILE
                    (
                         (ln_i <= it_data_rec.COUNT)
                     AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                     AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                     AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                     AND (lv_crowd_code   = NVL(it_data_rec(ln_i).crowd_code,lc_break_null))
                    ) LOOP -- �ڌQ���[�v
                    -- =====================================================
                    -- ���׃f�[�^�o��
                    -- =====================================================
                    prc_create_xml_data_line(
                      ov_errbuf          => lv_errbuf             -- �װ�ү����
                     ,ov_retcode         => lv_retcode            -- ���ݥ����
                     ,ov_errmsg          => lv_errmsg             -- հ�ް��װ�ү����
                     ,ir_param           => ir_param              -- ���Ұ�
                     ,it_data_rec        => it_data_rec(ln_i)     -- �擾ں���
                     ,in_i               => ln_i                  -- �A��
                     ,iot_xml_idx        => lt_xml_idx            -- XML�ް���ޕ\�̲��ޯ��
                     ,iot_xml_data_table => ot_xml_data_table     -- XML�ް�
                     ,on_sum_quantity           => ln_sum_quantity                 -- ���ʌv
                     ,on_sum_order_amount       => ln_sum_order_amount             -- �d�����z�v
                     ,on_sum_commission_price   => ln_sum_commission_price         -- ���K�v
                     ,on_sum_commission_tax_amount => ln_sum_commission_tax_amount -- ����Ōv(��)
                     ,on_sum_commission_amount  => ln_sum_commission_amount        -- ���K���z
                     ,on_sum_assess_amount      => ln_sum_assess_amount            -- ���ۋ��v
                     ,on_sum_payment            => ln_sum_payment                  -- �x���v
                     ,on_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- ����Ōv(�x)
                     ,on_sum_payment_amount     => ln_sum_payment_amount           -- �x�����z�v
                     ,on_sum_standard_amount    => ln_sum_standard_amount          -- �W�����z�v
                     ,on_sum_difference_amount  => ln_sum_difference_amount);      -- ���ٌv
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_process_expt ;
                    END IF ;
                    ln_i := ln_i + 1; -- ���C���J�E���g
                  END LOOP crowd_loop; -- �ڌQ���[�v
                  -- �ڌQ�R�[�hG�I���^�O
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
                END LOOP crowd_s_loop; -- ���Q���[�v
                -- �ڌQ�R�[�hLG�I���^�O
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                -- ���Q�R�[�hG�I���^�O
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_s' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
              END LOOP crowd_m_loop; -- ���Q���[�v
              -- ���Q�R�[�hLG�I���^�O
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_s' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
              -- ���Q�R�[�hG�I���^�O
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_m' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            END LOOP crowd_l_loop; -- ��Q���[�v
            -- ���Q�R�[�hLG�I���^�O
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_m' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- ��Q�R�[�hG�I���^�O
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_l' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
          END LOOP vendor_loop; -- �d���惋�[�v
          -- ��Q�R�[�hLG�I���^�O
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_l' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
          IF ( ir_param.party_code IS NULL ) THEN
            -- �d����G�I���^�O
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_vendor' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
          END IF;
--
        END LOOP item_div_loop; -- �i�ڋ敪���[�v
--
        IF ( ir_param.party_code IS NULL ) THEN
          -- �d����LG�I���^�O
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_vendor' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF;
        IF (ir_param.result_post IS NOT NULL)
          AND (ln_i > it_data_rec.COUNT) THEN -- �ŏI�f�[�^
          -- �����v�o��
          prc_create_xml_data_sum(
            ov_errbuf          => lv_errbuf             -- �װ�ү����
           ,ov_retcode         => lv_retcode            -- ���ݥ����
           ,ov_errmsg          => lv_errmsg             -- հ�ް��װ�ү����
           ,iot_xml_idx        => lt_xml_idx            -- XML�ް���ޕ\�̲��ޯ��
           ,iot_xml_data_table => ot_xml_data_table     -- XML�ް�
           ,in_sum_quantity           => ln_sum_quantity                 -- ���ʌv
           ,in_sum_order_amount       => ln_sum_order_amount             -- �d�����z�v
           ,in_sum_commission_price   => ln_sum_commission_price         -- ���K�v
           ,in_sum_commission_tax_amount => ln_sum_commission_tax_amount -- ����Ōv(��)
           ,in_sum_commission_amount  => ln_sum_commission_amount        -- ���K���z
           ,in_sum_assess_amount      => ln_sum_assess_amount            -- ���ۋ��v
           ,in_sum_payment            => ln_sum_payment                  -- �x���v
           ,in_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- ����Ōv(�x)
           ,in_sum_payment_amount     => ln_sum_payment_amount           -- �x�����z�v
           ,in_sum_standard_amount    => ln_sum_standard_amount          -- �W�����z�v
           ,in_sum_difference_amount  => ln_sum_difference_amount);      -- ���ٌv
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
        END IF;
        -- �i�ڋ敪G�I���^�O
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_article_div' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
      END LOOP result_post_loop; -- ���ѕ������[�v
      -- �i�ڋ敪LG�I���^�O
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_article_div' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      IF ( ir_param.result_post IS NULL ) THEN
        IF (ln_i > it_data_rec.COUNT) THEN -- �ŏI�f�[�^
          -- �����v�o��
          prc_create_xml_data_sum(
            ov_errbuf          => lv_errbuf             -- �װ�ү����
           ,ov_retcode         => lv_retcode            -- ���ݥ����
           ,ov_errmsg          => lv_errmsg             -- հ�ް��װ�ү����
           ,iot_xml_idx        => lt_xml_idx            -- XML�ް���ޕ\�̲��ޯ��
           ,iot_xml_data_table => ot_xml_data_table     -- XML�ް�
           ,in_sum_quantity           => ln_sum_quantity                 -- ���ʌv
           ,in_sum_order_amount       => ln_sum_order_amount             -- �d�����z�v
           ,in_sum_commission_price   => ln_sum_commission_price         -- ���K�v
           ,in_sum_commission_tax_amount => ln_sum_commission_tax_amount -- ����Ōv(��)
           ,in_sum_commission_amount  => ln_sum_commission_amount        -- ���K���z
           ,in_sum_assess_amount      => ln_sum_assess_amount            -- ���ۋ��v
           ,in_sum_payment            => ln_sum_payment                  -- �x���v
           ,in_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- ����Ōv(�x)
           ,in_sum_payment_amount     => ln_sum_payment_amount           -- �x�����z�v
           ,in_sum_standard_amount    => ln_sum_standard_amount          -- �W�����z�v
           ,in_sum_difference_amount  => ln_sum_difference_amount);      -- ���ٌv
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
        END IF;
        -- ���ѕ���G�I���^�O
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_result_post' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    IF ( ir_param.result_post IS NULL ) THEN
      -- ���ѕ���LG�I���^�O
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_result_post' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    END IF;
--
    -- �f�[�^LG�I���^�O
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : �p�����[�^�̎擾
   ***********************************************************************************/
  PROCEDURE prc_set_param(
      ov_errbuf             OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_proc_from          IN  VARCHAR2       -- 01 : �����N��(FROM)
     ,iv_proc_to            IN  VARCHAR2       -- 02 : �����N��(TO)
     ,iv_prod_div           IN  VARCHAR2       -- 03 : ���i�敪
     ,iv_item_div           IN  VARCHAR2       -- 04 : �i�ڋ敪
     ,iv_result_post        IN  VARCHAR2       -- 05 : ���ѕ���
     ,iv_party_code         IN  VARCHAR2       -- 06 : �d����
     ,iv_crowd_type         IN  VARCHAR2       -- 07 : �Q���
     ,iv_crowd_code         IN  VARCHAR2       -- 08 : �Q�R�[�h
     ,iv_acnt_crowd_code    IN  VARCHAR2       -- 09 : �o���Q�R�[�h
     ,or_param_rec          OUT rec_param_data -- ���̓p�����[�^�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_set_param' ; -- �v���O������
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
    lv_work_date         VARCHAR2(30) ;         -- �ϊ��p
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
    -- �p�����[�^�i�[
--    or_param_rec.proc_from       := iv_proc_from;       -- �����N��(FROM)
--    or_param_rec.proc_to         := iv_proc_to;         -- �����N��(TO)
    -- �����N��FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE(iv_proc_from, gc_char_yyyymm_format ),gc_char_yyyymm_format);
    IF ( lv_work_date IS NULL ) THEN
      or_param_rec.proc_from     := iv_proc_from;
    ELSE
      or_param_rec.proc_from     := lv_work_date;
    END IF;
    -- �����N��TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE(iv_proc_to, gc_char_yyyymm_format ), gc_char_yyyymm_format );
    IF ( lv_work_date IS NULL ) THEN
      or_param_rec.proc_to     := iv_proc_to;
    ELSE
      or_param_rec.proc_to     := lv_work_date;
    END IF;
    or_param_rec.prod_div        := iv_prod_div;        -- ���i�敪
    or_param_rec.item_div        := iv_item_div;        -- �i�ڋ敪
    or_param_rec.result_post     := iv_result_post;     -- ���ѕ���
    or_param_rec.party_code      := iv_party_code;      -- �d����
    or_param_rec.crowd_type      := iv_crowd_type;      -- �Q���
    or_param_rec.crowd_code      := iv_crowd_code;      -- �Q�R�[�h
    or_param_rec.acnt_crowd_code := iv_acnt_crowd_code; -- �o���Q�R�[�h
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
  END prc_set_param ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf             OUT VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_proc_from          IN  VARCHAR2        --   01 : �����N��(FROM)
     ,iv_proc_to            IN  VARCHAR2        --   02 : �����N��(TO)
     ,iv_prod_div           IN  VARCHAR2        --   03 : ���i�敪
     ,iv_item_div           IN  VARCHAR2        --   04 : �i�ڋ敪
     ,iv_result_post        IN  VARCHAR2        --   05 : ���ѕ���
     ,iv_party_code         IN  VARCHAR2        --   06 : �d����
     ,iv_crowd_type         IN  VARCHAR2        --   07 : �Q���
     ,iv_crowd_code         IN  VARCHAR2        --   08 : �Q�R�[�h
     ,iv_acnt_crowd_code    IN  VARCHAR2        --   09 : �o���Q�R�[�h
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
    lr_param_rec         rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string        VARCHAR2(32000) ;
    ln_retcode           NUMBER ;
--
    ------------------------------
    -- �w�l�k�p
    ------------------------------
    lt_main_data              tab_data_type_dtl; -- �擾���R�[�h�\
    lt_xml_data_table         XML_DATA;          -- �w�l�k�f�[�^�^�O�\
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
    -- �p�����[�^�i�[
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_proc_from          => iv_proc_from        -- 01 : �����N��(FROM)
       ,iv_proc_to            => iv_proc_to          -- 02 : �����N��(TO)
       ,iv_prod_div           => iv_prod_div         -- 03 : ���i�敪
       ,iv_item_div           => iv_item_div         -- 04 : �i�ڋ敪
       ,iv_result_post        => iv_result_post      -- 05 : ���ѕ���
       ,iv_party_code         => iv_party_code       -- 06 : �d����
       ,iv_crowd_type         => iv_crowd_type       -- 07 : �Q���
       ,iv_crowd_code         => iv_crowd_code       -- 08 : �Q�R�[�h
       ,iv_acnt_crowd_code    => iv_acnt_crowd_code  -- 09 : �o���Q�R�[�h
       ,or_param_rec          => lr_param_rec        -- ���̓p�����[�^�Q
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param      => lr_param_rec   -- ���̓p�����[�^�Q
       ,ot_data_rec   => lt_main_data   -- �擾���R�[�h�Q
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,it_data_rec       => lt_main_data       -- �擾���R�[�h�Q
       ,ot_xml_data_table => lt_xml_data_table  -- XML�f�[�^
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML�o�͏���
    -- =====================================================
    prc_out_xml(
        ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec      -- ���̓p�����[�^�Q
       ,it_xml_data_table => lt_xml_data_table -- �擾���R�[�h�Q
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF (lt_main_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    END IF;
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
  PROCEDURE main(
      errbuf                OUT   VARCHAR2, -- �G���[���b�Z�[�W
      retcode               OUT   VARCHAR2, -- �G���[�R�[�h
      iv_proc_from          IN    VARCHAR2, -- 01 : �����N��(FROM)
      iv_proc_to            IN    VARCHAR2, -- 02 : �����N��(TO)
      iv_prod_div           IN    VARCHAR2, -- 03 : ���i�敪
      iv_item_div           IN    VARCHAR2, -- 04 : �i�ڋ敪
      iv_result_post        IN    VARCHAR2, -- 05 : ���ѕ���
      iv_party_code         IN    VARCHAR2, -- 06 : �d����
      iv_crowd_type         IN    VARCHAR2, -- 07 : �Q���
      iv_crowd_code         IN    VARCHAR2, -- 08 : �Q�R�[�h
      iv_acnt_crowd_code    IN    VARCHAR2  -- 09 : �o���Q�R�[�h
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
    submain(
        ov_errbuf             => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_proc_from          => iv_proc_from       -- 01 : �����N��(FROM)
       ,iv_proc_to            => iv_proc_to         -- 02 : �����N��(TO)
       ,iv_prod_div           => iv_prod_div        -- 03 : ���i�敪
       ,iv_item_div           => iv_item_div        -- 04 : �i�ڋ敪
       ,iv_result_post        => iv_result_post     -- 05 : ���ѕ���
       ,iv_party_code         => iv_party_code      -- 06 : �d����
       ,iv_crowd_type         => iv_crowd_type      -- 07 : �Q���
       ,iv_crowd_code         => iv_crowd_code      -- 08 : �Q�R�[�h
       ,iv_acnt_crowd_code    => iv_acnt_crowd_code -- 09 : �o���Q�R�[�h
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
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
END xxcmn770025c ;
/
