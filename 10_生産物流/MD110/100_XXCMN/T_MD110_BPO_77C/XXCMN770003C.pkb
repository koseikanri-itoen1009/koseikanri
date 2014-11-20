CREATE OR REPLACE PACKAGE BODY xxcmn770003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770003C(body)
 * Description      : �󕥎c���\�i�U�j
 * MD.050/070       : �����Y�؏������[Issue1.0(T_MD050_BPO_770)
 *                  : �����Y�؏������[Issue1.0(T_MD070_BPO_77C)
 * Version          : 1.8
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                      Description
 * -------------------------- ------------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : XML�^�O�ɕϊ�����B
 *  fnc_item_unit_pric_get    FUNCTION  : �i�ڂ̌����̎擾
 *  prc_initialize            PROCEDURE : �O����(C-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(C-3)
 *  prc_item_sum              PROCEDURE : �i�ږ��׉��Z����
 *  prc_item_init             PROCEDURE : �i�ږ��׃N���A����
 *  prc_create_xml_data       PROCEDURE : XML�f�[�^�쐬(C-4)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   Y.Majikina       �V�K�쐬
 *  2008/05/15    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂��ꂽ���A�G���[
 *                                       �ƂȂ�_���C���B
 *                                       �S�������A�S���Җ��̍ő咷�������C���B
 *  2008/05/30    1.2   Y.Ishikawa       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *
 *  2008/06/12    1.3   I.Higa           ����敪��"�I����"�܂���"�I����"�̏ꍇ�A�}�C�i�X�f�[�^��
 *                                       �����Ă���̂Ő�Βl�v�Z���s�킸�A�ݒ�l�ŏW�v���s���B
 *  2008/06/13    1.4   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜�B
 *  2008/06/24    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/05    1.7   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma03_v�v
 *  2008/08/28    1.8   A.Shiina         ������ʂ͎擾���Ɏ󕥋敪���|����B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal          CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn            CONSTANT VARCHAR2(1)  := '1';
  gv_status_error           CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
  gv_haifn                  CONSTANT VARCHAR2(1)  := '-';
  gv_ja                     CONSTANT VARCHAR2(2)  := 'JA';
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'XXCMN770003C' ;   -- �p�b�P�[�W��
  gv_print_name           CONSTANT VARCHAR2(40) := '�� �� �c �� �\ �i�U�j' ;    -- ���[��
  gv_item_div             CONSTANT VARCHAR2(10) := '���i�敪';
  gv_art_div              CONSTANT VARCHAR2(10) := '�i�ڋ敪';
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gv_crowd_type           CONSTANT VARCHAR2(20)  :=  'XXCMN_MC_OUPUT_DIV';
  gv_report_type          CONSTANT VARCHAR2(100) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE';
--
  ------------------------------
  -- �o�͍��ڂ̗�ʒu�ő�l
  ------------------------------
  gc_print_pos_max        CONSTANT NUMBER := 13;--���ڏo�͈ʒu
--
  ------------------------------
  -- �����敪
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0';--���ی���
  gc_cost_st              CONSTANT VARCHAR2(1) := '1';--�W������
--
  ------------------------------
  -- ����敪
  ------------------------------
  gv_div_name             CONSTANT VARCHAR2(6) := '�I����';
--
  ------------------------------
  -- ���b�g�Ǘ��敪
  ------------------------------
  gc_lot_n                CONSTANT xxcmn_lot_each_item_v.lot_ctl%TYPE := 0; -- ���b�g�Ǘ��Ȃ�
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN';-- �A�v���P�[�V����
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  gc_d                    CONSTANT VARCHAR2(1)  := 'D';
  gc_n                    CONSTANT VARCHAR2(1)  := 'N';
  gc_t                    CONSTANT VARCHAR2(1)  := 'T';
  gc_z                    CONSTANT VARCHAR2(1)  := 'Z';
  ------------------------------
  -- XML�o�͍��ڏꏊ
  ------------------------------
  gc_hamaoka_num          CONSTANT NUMBER := 1;  -- �l���i�󕥁j
  gc_rec_kind_num         CONSTANT NUMBER := 2;  -- �i��ړ��i�󕥁j
  gc_rec_whse_num         CONSTANT NUMBER := 3;  -- �q�Ɉړ��i�󕥁j
  gc_rec_etc_num          CONSTANT NUMBER := 4;  -- ���̑��i�󕥁j
  gc_resale_num           CONSTANT NUMBER := 5;  -- �]���i���o�j
  gc_aband_num            CONSTANT NUMBER := 6;  -- �p�p�i���o�j
  gc_sample_num           CONSTANT NUMBER := 7;  -- ���{�i���o�j
  gc_admin_num            CONSTANT NUMBER := 8;  -- �������o�i���o�j
  gc_acnt_num             CONSTANT NUMBER := 9;  -- �o�����o�i���o�j
  gc_dis_kind_num         CONSTANT NUMBER := 10; -- �i��ړ��i���o�j
  gc_dis_whse_num         CONSTANT NUMBER := 11; -- �q�Ɉړ��i���o�j
  gc_dis_etc_num          CONSTANT NUMBER := 12; -- ���̑��i���o�j
  gc_inv_he_num           CONSTANT NUMBER := 13; -- �I�����Ձi���o�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
    process_year        VARCHAR2(6),                             -- �����N��
    item_division       mtl_categories_b.segment1%TYPE,          -- ���i�敪
    art_division        mtl_categories_b.segment1%TYPE,          -- �i�ڋ敪
    report_type         NUMBER,                                  -- ���[�敪
    warehouse_code      ic_whse_mst.whse_code%TYPE,              -- �q�ɃR�[�h
    crowd_type          fnd_lookup_values.lookup_code%TYPE,      -- �Q���
    crowd_code          xxpo_categories_v.category_code%TYPE,    -- �Q�R�[�h
    account_code        xxpo_categories_v.category_code%TYPE     -- �o���Q�R�[�h
  );
--
  -- �i�ږ��׏W�v���R�[�h
  TYPE qty_array IS VARRAY(15) OF NUMBER;
  qty qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  TYPE amt_array IS VARRAY(15) OF NUMBER;
  amt qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
--
  -- �󕥎c���\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
    whse_code          ic_tran_pnd.whse_code%TYPE,              -- �q�ɃR�[�h
    whse_name          ic_whse_mst.whse_name%TYPE,              -- �q�ɖ�
    trans_qty          ic_tran_pnd.trans_qty%TYPE,              -- �������
    trans_date         ic_tran_pnd.trans_date%TYPE,
    div_name           xxcmn_lookup_values_v.meaning%TYPE,      -- ����敪
    pay_div            xxcmn_rcv_pay_mst.rcv_pay_div%TYPE,      -- �󕥋敪
    item_id            ic_item_mst_b.item_id%TYPE,              -- �i��ID
    item_code          ic_item_mst_b.item_desc1%TYPE,           -- �i�ڃR�[�h
    item_name          xxcmn_item_mst_b.item_short_name%TYPE,   -- �i�ږ���
    column_no          fnd_lookup_values.attribute3%TYPE,       -- ���ڈʒu
    cost_div           ic_item_mst_b.attribute15%TYPE,          -- �����Ǘ��敪
    lot_kbn            xxcmn_lot_each_item_v.lot_ctl%TYPE,      -- ���b�g�Ǘ��敪
    crowd_code         mtl_categories_b.segment1%TYPE,          -- �ڌQ�R�[�h
    crowd_small        mtl_categories_b.segment1%TYPE,          -- ���Q�R�[�h
    crowd_medium       mtl_categories_b.segment1%TYPE,          -- ���Q�R�[�h
    crowd_large        mtl_categories_b.segment1%TYPE,          -- ��Q�R�[�h
    act_unit_price     xxcmn_lot_cost.unit_ploce%TYPE           -- ���ےP��
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_exec_start             DATE;             -- �����N���̊J�n��
  gd_exec_end               DATE;             -- �����N���̏I����
  gv_exec_start             VARCHAR2(20);     -- �����N���̊J�n��
  gv_exec_end               VARCHAR2(20);     -- �����N���̏I����
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
-- ���[���
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- �S����
  gv_report_div_name        fnd_lookup_values.meaning%TYPE;                   -- ���[��ʖ�
  gv_item_div_name          mtl_categories_tl.description%TYPE;               -- ���i�敪��
  gv_art_div_name           mtl_categories_tl.description%TYPE;               -- �i�ڋ敪��
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;               -- �Q��ʖ�
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12);    -- ���[ID
  gd_exec_date              DATE        ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  �Œ蕔 END   ############################
--
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
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
--
  END fnc_conv_xml;
--
--
--
--
  /**********************************************************************************
  * Function Name    : fnc_item_unit_pric_get
  * Description      : �i�ڂ̌����̎擾
  ***********************************************************************************/
  FUNCTION fnc_item_unit_pric_get (
    in_pos   IN   NUMBER             -- �i�ڃ��R�[�h�z��ʒu
  )
  RETURN NUMBER
  IS
--
    -- *** ���[�U��`�萔 ***
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_item_unit_pric_get';   -- �v���O������
    cn_zero        CONSTANT NUMBER        := 0;
    -- *** ���[�U��`�ϐ� ***
    --�����߂�l
    ln_unit_price  NUMBER DEFAULT 0;
--
  BEGIN
    --�����敪���W�������̂Ƃ�
    IF  ((gt_main_data(in_pos).cost_div = gc_cost_st)
      OR ((gt_main_data(in_pos).cost_div = gc_cost_ac)
      AND (gt_main_data(in_pos).lot_kbn = gc_lot_n))) THEN
      -- =========================================
      -- �W�������}�X�^���W���P�����擾���܂��B=
      -- =========================================
      BEGIN
        SELECT  price_v.stnd_unit_price  as price
          INTO  ln_unit_price
          FROM  xxcmn_stnd_unit_price_v price_v
         WHERE  price_v.item_id    = gt_main_data(in_pos).item_id
            AND  ((price_v.start_date_active IS NULL )
             OR   (price_v.start_date_active    <= gt_main_data(in_pos).trans_date))
            AND  ((price_v.end_date_active   IS NULL )
             OR   ( price_v.end_date_active     >= gt_main_data(in_pos).trans_date));
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_unit_price := cn_zero;
      END;
      RETURN  ln_unit_price;
--
     --�����敪�����ی����̂Ƃ�
    ELSIF (gt_main_data(in_pos).cost_div = gc_cost_ac)  THEN
      RETURN NVL( gt_main_data(in_pos).act_unit_price, cn_zero );
    ELSE
      RETURN cn_zero;
    END IF;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
--
  END fnc_item_unit_pric_get;
--
--
--
--
  /**********************************************************************************
  * Procedure Name   : prc_initialize
  * Description      : �O����(C-1)
  ***********************************************************************************/
  PROCEDURE prc_initialize (
      ir_param      IN     rec_param_data,   --    ���̓p�����[�^�Q
      ov_errbuf     OUT    VARCHAR2,         --    �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    OUT    VARCHAR2,         --    ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     OUT    VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize'; -- �v���O������
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
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION;     -- �l�擾�G���[
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
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- =====================================================
    -- ���i�敪���擾
    -- =====================================================
    BEGIN
      SELECT  cat.description
        INTO  gv_item_div_name
        FROM  xxcmn_categories2_v cat
       WHERE  cat.category_set_name = gv_item_div
         AND  cat.segment1          = ir_param.item_division;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- =====================================================
    -- �i�ڋ敪���擾
    -- =====================================================
    BEGIN
      SELECT  cat.description
        INTO  gv_art_div_name
        FROM  xxcmn_categories2_v cat
       WHERE  cat.category_set_name = gv_art_div
         AND  cat.segment1          = ir_param.art_division;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- ���[��ʎ擾
    -- ====================================================
    BEGIN
      SELECT  lvv.meaning
        INTO  gv_report_div_name
        FROM  xxcmn_lookup_values_v lvv
       WHERE  lvv.lookup_type   = gv_report_type
         AND  lvv.lookup_code   = ir_param.report_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- �Q��ʖ��擾
    -- ====================================================
    BEGIN
      SELECT  lvv.meaning
        INTO  gv_crowd_kind_name
        FROM  xxcmn_lookup_values_v lvv
       WHERE  lvv.lookup_type   = gv_crowd_type
         AND  lvv.lookup_code   = ir_param.crowd_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
      ov_retcode := lv_retcode;
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
  END prc_initialize;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(C-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data,            --    ���̓p�����[�^�Q
      ot_data_rec   OUT NOCOPY tab_data_type_dtl,  --    �擾���R�[�h�Q
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
    cv_process_year   CONSTANT VARCHAR2(8)  := '�����N��';
    cv_min            CONSTANT VARCHAR2(2)  := '-1';
    cv_one            CONSTANT VARCHAR2(1)  := '1';
    cv_two            CONSTANT VARCHAR2(1)  := '2';
    cv_three          CONSTANT VARCHAR2(1)  := '3';
    cv_four           CONSTANT VARCHAR2(1)  := '4';
    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';
    cv_lang           CONSTANT VARCHAR2(2)  := 'JA';
    cv_lookup         CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cv_lookup2        CONSTANT VARCHAR2(40) := 'XXCMN_DEALINGS_DIV';
    cv_meaning        CONSTANT VARCHAR2(10) := '�i�ڐU��';
    cn_zero           CONSTANT NUMBER       := 0;
    cn_one            CONSTANT NUMBER       := 1;
    cn_min            CONSTANT NUMBER       := -1;
    -- �����^�C�v
    cv_xfer           CONSTANT VARCHAR2(4)  := 'XFER';
    cv_trni           CONSTANT VARCHAR2(4)  := 'TRNI';
    cv_adji           CONSTANT VARCHAR2(4)  := 'ADJI';
    cv_prod           CONSTANT VARCHAR2(4)  := 'PROD';
    cv_omso           CONSTANT VARCHAR2(4)  := 'OMSO';
    cv_porc           CONSTANT VARCHAR2(4)  := 'PORC';
    -- ���R�R�[�h
    cv_reason_123     CONSTANT VARCHAR2(4)  := 'X123';
    cv_reason_911     CONSTANT VARCHAR2(4)  := 'X911';
    cv_reason_912     CONSTANT VARCHAR2(4)  := 'X912';
    cv_reason_921     CONSTANT VARCHAR2(4)  := 'X921';
    cv_reason_922     CONSTANT VARCHAR2(4)  := 'X922';
    cv_reason_941     CONSTANT VARCHAR2(4)  := 'X941';
    cv_reason_931     CONSTANT VARCHAR2(4)  := 'X931';
    cv_reason_932     CONSTANT VARCHAR2(4)  := 'X932';
    cv_reason_942     CONSTANT VARCHAR2(4)  := 'X942';
    cv_reason_951     CONSTANT VARCHAR2(4)  := 'X951';
    cv_reason_988     CONSTANT VARCHAR2(4)  := 'X988';
    cv_dealing_309    CONSTANT VARCHAR2(3)  := '309';
    lc_f_time         CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time         CONSTANT VARCHAR2(10) := ' 23:59:59';
--
    -- *** ���[�J���E�ϐ� ***
    -- XFER
    lv_select_xfer       VARCHAR2(32000);
    lv_from_xfer         VARCHAR2(32000);
    lv_where_xfer        VARCHAR2(32000);
    lv_sql_xfer          VARCHAR2(32000);
    -- TRNI
    lv_select_trni       VARCHAR2(32000);
    lv_from_trni         VARCHAR2(32000);
    lv_where_trni        VARCHAR2(32000);
    lv_sql_trni          VARCHAR2(32000);
    -- ADJI_1
    lv_select_adji_1     VARCHAR2(32000);
    lv_from_adji_1       VARCHAR2(32000);
    lv_where_adji_1      VARCHAR2(32000);
    lv_sql_adji_1        VARCHAR2(32000);
    -- ADJI_2
    lv_select_adji_2     VARCHAR2(32000);
    lv_from_adji_2       VARCHAR2(32000);
    lv_where_adji_2      VARCHAR2(32000);
    lv_sql_adji_2        VARCHAR2(32000);
    --  ADJI_3
    lv_select_adji_3     VARCHAR2(32000);
    lv_from_adji_3       VARCHAR2(32000);
    lv_where_adji_3      VARCHAR2(32000);
    lv_sql_adji_3        VARCHAR2(32000);
    -- ADJI_4
    lv_select_adji_4     VARCHAR2(32000);
    lv_from_adji_4       VARCHAR2(32000);
    lv_where_adji_4      VARCHAR2(32000);
    lv_sql_adji_4        VARCHAR2(32000);
    -- PROD
    lv_select_prod       VARCHAR2(32000);
    lv_from_prod         VARCHAR2(32000);
    lv_where_prod        VARCHAR2(32000);
    lv_sql_prod          VARCHAR2(32000);
    --  OMSO
    lv_select_omso       VARCHAR2(32000);
    lv_from_omso         VARCHAR2(32000);
    lv_where_omso        VARCHAR2(32000);
    lv_sql_omso          VARCHAR2(32000);
    --  PORC
    lv_select_porc       VARCHAR2(32000);
    lv_from_porc         VARCHAR2(32000);
    lv_where_porc        VARCHAR2(32000);
    lv_sql_porc          VARCHAR2(32000);
    -- ����SELECT
    lv_select            VARCHAR2(32000);
    -- ����WHERE
    lv_where             VARCHAR2(32000);
    -- ����WHERE itp
    lv_where_itp         VARCHAR2(32000);
    -- ����WHERE itc
    lv_where_itc         VARCHAR2(32000);
    -- ORDER BY
    lv_order             VARCHAR2(32000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE ref_cursor IS REF CURSOR ;
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
    -- ====================================================
    -- ���t���擾
    -- ====================================================
    -- �����N���E�J�n��
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.process_year , gc_char_m_format);
    IF ( gd_exec_start IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_process_year
                                             ,'ERROR_VALUE'
                                             ,ir_param.process_year ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
--
    -- �����N���E�I����
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
--
    -- ===============================================================================
    -- ���� SELECT
    -- ===============================================================================
    lv_select := ' xleiv.item_id           AS  item_id, '    -- �i��ID
              || ' xleiv.item_code         AS  item_code, '  -- �i�ڃR�[�h
              || ' xleiv.item_short_name   AS  item_name, '  -- �i�ږ���
              || ' xlvv.attribute3         AS  column_no, '  -- �o�͏ꏊ
              || ' xleiv.item_attribute15  AS  cost_div, '   -- �����Ǘ��敪
              || ' xleiv.lot_ctl           AS  lot_ctl, ';   -- ���b�g�Ǘ��敪
--
    -- =======================================
    -- �Q��ʂɎ擾���ڂ�ύX
    -- =======================================
    -- �Q��ʂ�3�F�Q�ʂ��I������Ă���ꍇ
    IF ( ir_param.crowd_type = cv_three ) THEN
      lv_select := lv_select
                || ' xleiv.crowd_code                  AS crowd_code,   '   -- �ڌQ�R�[�h
                || ' SUBSTR( xleiv.crowd_code, 1, 3 )  AS crowd_small,  '   -- ���Q�R�[�h
                || ' SUBSTR( xleiv.crowd_code, 1, 2 )  AS crowd_medium, '   -- ���Q�R�[�h
                || ' SUBSTR( xleiv.crowd_code, 1, 1 )  AS crowd_large,  ';  -- ��Q�R�[�h
    -- �Q��ʂ�4�F�o���Q�ʂ��I������Ă���ꍇ
    ELSIF ( ir_param.crowd_type = cv_four ) THEN
      lv_select := lv_select
                || ' xleiv.acnt_crowd_code                  AS crowd_code,   '   -- �ڌQ�R�[�h
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 3 )  AS crowd_small,  '   -- ���Q�R�[�h
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 2 )  AS crowd_medium, '   -- ���Q�R�[�h
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 1 )  AS crowd_large,  ';  -- ��Q�R�[�h
    END IF;
    lv_select := lv_select
              || ' xleiv.actual_unit_price   AS act_unit_price '; -- ���ےP��
--
    -- ===============================================================================
    -- ���� WHERE
    -- ===============================================================================
    lv_where := ' AND  xlvv.enabled_flag      = '''  || cv_yes || ''''
             || ' AND  xlvv.lookup_type        = ''' || cv_lookup || ''''
             || ' AND  xlvv.language                = ''' || cv_lang || ''''
             || ' AND  xlvv.source_lang             = ''' || cv_lang || ''''
             || ' AND  xlvv.attribute3  IS NOT NULL '
             || ' AND  xleiv.prod_div     = ''' || ir_param.item_division || ''''
             || ' AND  xleiv.item_div     = ''' || ir_param.art_division  || '''';
--
    -- ====================================
    -- �Q��ʕʂɎ擾������ǉ�
    -- ====================================
    -- �Q��ʂ�3�F�Q�ʂ̏ꍇ
    IF (( ir_param.crowd_type = cv_three )
      AND ( ir_param.crowd_code IS NOT NULL )) THEN
      lv_where := lv_where
               || ' AND xleiv.crowd_code = ''' || ir_param.crowd_code || '''';
    -- �Q��ʂ�4�F�o���Q�ʂ̏ꍇ
    ELSIF (( ir_param.crowd_type = cv_four )
      AND  ( ir_param.account_code IS NOT NULL )) THEN
      lv_where := lv_where
               || ' AND xleiv.acnt_crowd_code = ''' || ir_param.account_code || '''';
    END IF;
--
--
    -- ===============================================================================
    -- ���� WHERE ITP
    -- ===============================================================================
    lv_where_itp := ' AND  itp.trans_date   >= FND_DATE.STRING_TO_DATE( '
                 || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                 || ' AND  itp.trans_date   <= FND_DATE.STRING_TO_DATE('
                 || '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
                 || ' AND  ((xlvv.start_date_active IS NULL ) '
                 || '  OR   (xlvv.start_date_active    <= TRUNC(itp.trans_date))) '
                 || ' AND  ((xlvv.end_date_active   IS NULL ) '
                 || '  OR   ( xlvv.end_date_active     >= TRUNC(itp.trans_date))) '
                 || ' AND  itp.item_id                  = xleiv.item_id '
                 || ' AND  ((xleiv.start_date_active IS NULL ) '
                 || '  OR   (xleiv.start_date_active   <= TRUNC(itp.trans_date))) '
                 || ' AND  ((xleiv.end_date_active  IS NULL) '
                 || '  OR   (xleiv.end_date_active     >= TRUNC(itp.trans_date))) '
                 || ' AND  itp.completed_ind    = ' || cn_one
                 || ' AND  xleiv.lot_id                 = itp.lot_id ';
    -- ====================================
    -- ���[��ʂ�1�F�q�ɕʁE�i�ڕʂ̏ꍇ
    -- ====================================
    IF ( ir_param.report_type = cv_one ) THEN
      lv_where_itp := lv_where_itp
                    || ' AND iwm.whse_code = itp.whse_code ';
      -- �q�ɃR�[�h���w�肳��Ă����ꍇ
      IF ( ir_param.warehouse_code IS NOT NULL ) THEN
        lv_where_itp := lv_where_itp
                      || ' AND iwm.whse_code  = ''' || ir_param.warehouse_code || '''';
      END IF;
    END IF;
--
    -- ===============================================================================
    -- ���� WHERE ITC
    -- ===============================================================================
    lv_where_itc := '   AND  itc.trans_date     >= FND_DATE.STRING_TO_DATE( '
                 || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                 || '   AND  itc.trans_date     <= FND_DATE.STRING_TO_DATE('
                 || '''' || gv_exec_end || ''', '''   || gc_char_dt_format || ''' )'
                 || '   AND  ((xlvv.start_date_active IS NULL ) '
                 || '    OR   (xlvv.start_date_active  <= TRUNC(itc.trans_date))) '
                 || '   AND  ((xlvv.end_date_active   IS NULL ) '
                 || '    OR   ( xlvv.end_date_active  >= TRUNC(itc.trans_date))) '
                 || '   AND  itc.item_id               = xleiv.item_id '
                 || '   AND  ((xleiv.start_date_active IS NULL ) '
                 || '    OR   (xleiv.start_date_active  <= TRUNC(itc.trans_date))) '
                 || '   AND  ((xleiv.end_date_active IS NULL) '
                 || '    OR   (xleiv.end_date_active    >= TRUNC(itc.trans_date))) '
                 || '   AND  xleiv.lot_id                = itc.lot_id ';
--
    -- ====================================
    -- ���[��ʂ�1�F�q�ɕʁE�i�ڕʂ̏ꍇ
    -- ====================================
    IF ( ir_param.report_type = cv_one ) THEN
      lv_where_itc := lv_where_itc
                    || ' AND iwm.whse_code = itc.whse_code ';
      -- �q�ɃR�[�h���w�肳��Ă����ꍇ
      IF ( ir_param.warehouse_code IS NOT NULL ) THEN
        lv_where_itc := lv_where_itc
                      || ' AND iwm.whse_code = ''' || ir_param.warehouse_code || '''';
      END IF;
    END IF;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- ============================================================================
    -- XFER
    -- ============================================================================
    lv_select_xfer := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_xfer := lv_select_xfer
                     || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                     || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_xfer := lv_select_xfer
                     || ' NULL                 AS  whse_code, '
                     || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_xfer := lv_select_xfer
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- �������
                   || ' itp.trans_qty * TO_NUMBER(xfer_v.rcv_pay_div) AS  trans_qty, '  -- �������
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- �����
                   || ' xfer_v.dealings_div_name AS  div_name, ' -- ����敪��
                   || ' xfer_v.rcv_pay_div     AS  pay_div, ';    -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_xfer := ' FROM '
                 || ' ic_tran_pnd                 itp, '     -- �݌Ƀg����
                 || ' xxcmn_rcv_pay_mst_xfer_v    xfer_v, '
                 || ' ic_xfer_mst                 ixm, '     -- OPM�݌ɓ]���}�X�^
                 || ' xxinv_mov_req_instr_lines   xmril, '   -- �ړ��˗��^�w�����ׁi�A�h�I���j
                 || ' xxcmn_lookup_values2_v      xlvv, '    -- �N�C�b�N�R�[�h���VIEW2
                 || ' xxcmn_lot_each_item_v       xleiv  ';  -- ���b�g�ʕi�ڏ��View
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_xfer := lv_from_xfer
                   || ' , ic_whse_mst             iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_xfer := ' WHERE '
                  || '      itp.doc_type         = ''' || cv_xfer || ''''
                  || ' AND  itp.completed_ind    = '   || cn_one
                  || ' AND  itp.reason_code      = xfer_v.reason_code '
                  || ' AND  xfer_v.doc_type      = itp.doc_type '
                  || ' AND  xfer_v.rcv_pay_div   = CASE '
                  || '                              WHEN itp.trans_qty >= ' || cn_zero
                  || '                              THEN ''' || cv_one || ''''
                  || '                              ELSE ''' || cv_min || ''''
                  || '                             END '
                  || ' AND  itp.doc_id           = ixm.transfer_id '
                  || ' AND  ixm.attribute1       = xmril.mov_line_id '
                  || ' AND  xfer_v.dealings_div  = xlvv.meaning ';
--
    -- XFER:SQL
    lv_sql_xfer := lv_select_xfer || lv_select
                || lv_from_xfer   || lv_where_xfer
                || lv_where_itp   || lv_where ;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- =========================================================================================
    -- TRNI
    -- =========================================================================================
    lv_select_trni := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_trni := lv_select_trni
                     || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                     || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_trni := lv_select_trni
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_trni := lv_select_trni
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itc.trans_qty          AS  trans_qty, '  -- �������
                   || ' itc.trans_qty * TO_NUMBER(trni_v.rcv_pay_div) AS  trans_qty, '  -- �������
-- 2008/08/28 v1.8 UPDATE END
                   || ' itc.trans_date         AS  trans_date, '  -- �����
                   || ' trni_v.dealings_div_name AS  div_name, ' -- ����敪��
                   || ' trni_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_trni := ' FROM '
                 || ' ic_tran_cmp                itc, '
                 || ' xxcmn_rcv_pay_mst_trni_v   trni_v, '
                 || ' ic_adjs_jnl                iaj, '    -- OPM�݌ɒ����W���[�i��
                 || ' ic_jrnl_mst                ijm, '    -- OPM�W���[�i���}�X�^
                 || ' xxinv_mov_req_instr_lines  xmril, '  -- �ړ��˗��^�w�����ׁi�A�h�I���j
                 || ' xxcmn_lookup_values2_v     xlvv, '   -- �N�C�b�N�R�[�h���VIEW2
                 || ' xxcmn_lot_each_item_v      xleiv ';  -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_trni := lv_from_trni
                   || ' , ic_whse_mst            iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_trni := ' WHERE '
                  || '        itc.doc_type         = ''' || cv_trni || ''''
                  || '   AND  itc.doc_type         = trni_v.doc_type '
                  || '   AND  itc.reason_code      = trni_v.reason_code '
                  || '   AND  trni_v.rcv_pay_div  = CASE '
                  || '                                WHEN itc.trans_qty >= ' || cn_zero
                  || '                                THEN ''' || cv_one || ''''
                  || '                                ELSE ''' || cv_min || ''''
                  || '                              END '
                  || '   AND  itc.doc_type         = iaj.trans_type '
                  || '   AND  itc.doc_id           = iaj.doc_id '
                  || '   AND  itc.doc_line         = iaj.doc_line '
                  || '   AND  iaj.journal_id       = ijm.journal_id '
                  || '   AND  ijm.attribute1       = xmril.mov_line_id '
                  || '   AND  trni_v.dealings_div  = xlvv.meaning ';
    -- TRNI:SQL
    lv_sql_trni := lv_select_trni || lv_select
                || lv_from_trni   || lv_where_trni
                || lv_where_itc   || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- �݌ɒ���(�d����ԕi�A�l������A�ړ����ђ����ȊO)
    lv_select_adji_1 := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_1 := lv_select_adji_1
                       || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                       || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_adji_1 := lv_select_adji_1
                       || ' NULL                 AS whse_code, '
                       || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_adji_1 := lv_select_adji_1
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- �������
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- �������
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- �����
                     || ' adji_v.dealings_div_name AS  div_name, ' -- ����敪��
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_adji_1 := ' FROM '
                   || ' ic_tran_cmp               itc, '
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv,  '  -- �N�C�b�N�R�[�h���VIEW2
                   || ' xxcmn_lot_each_item_v     xleiv ';  -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_1 := lv_from_adji_1
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_adji_1 := ' WHERE '
                    || '        itc.doc_type          = ''' || cv_adji || ''''
                    || '   AND  itc.doc_type          = adji_v.doc_type '
                    || '   AND  ((itc.reason_code     = ''' || cv_reason_911 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_912 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_921 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_922 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_941 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_931 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_932 || ''' ))'
                    || '   AND  itc.reason_code       = adji_v.reason_code '
                    || '   AND  adji_v.dealings_div   = xlvv.meaning ';
    -- ADJI_1:SQL
    lv_sql_adji_1 := lv_select_adji_1 || lv_select
                  || lv_from_adji_1   || lv_where_adji_1
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- �݌ɒ���(�l�����)
    lv_select_adji_2 := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_2 := lv_select_adji_2
                       || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                       || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_adji_2 := lv_select_adji_2
                       || ' NULL                 AS  whse_code, '
                       || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_adji_2 := lv_select_adji_2
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- �������
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- �������
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- �����
                     || ' adji_v.dealings_div_name AS  div_name, ' -- ����敪��
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_adji_2 := ' FROM '
                   || ' ic_tran_cmp               itc, '       -- OPM�����݌Ƀg����
                   || ' ic_adjs_jnl               iaj, '       -- OPM�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst               ijm, '       -- OPM�W���[�i���}�X�^
                   || ' xxpo_namaha_prod_txns     xnpt, '      -- ���Z���уA�h�I��
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv, '      -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_lot_each_item_v     xleiv ';     -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_2 := lv_from_adji_2
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_adji_2 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND itc.reason_code      = ''' || cv_reason_988 || ''''
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND xnpt.entry_number    = ijm.attribute1 '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_2:SQL
    lv_sql_adji_2 := lv_select_adji_2 || lv_select
                  || lv_from_adji_2   || lv_where_adji_2
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- �݌ɒ���(�ړ����ђ���)
    lv_select_adji_3 := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_3 := lv_select_adji_3
                       || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                       || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_adji_3 := lv_select_adji_3
                       || ' NULL                 AS  whse_code, '
                       || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_adji_3 := lv_select_adji_3
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- �������
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- �������
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- �����
                     || ' adji_v.dealings_div_name AS  div_name, ' -- ����敪��
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_adji_3 := ' FROM '
                   || ' ic_tran_cmp                itc, '      -- opm�����݌Ƀg����
                   || ' ic_adjs_jnl                iaj, '      -- opm�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst                ijm, '      -- opm�W���[�i���}�X�^
                   || ' xxinv_mov_req_instr_lines  xmrl  , '
                   || ' xxcmn_rcv_pay_mst_adji_v   adji_v, '
                   || ' xxcmn_lookup_values2_v     xlvv, '     -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_lot_each_item_v      xleiv ';    -- ���b�g�ʕi�ڏ��view
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_3 := lv_from_adji_3
                     || ' , ic_whse_mst            iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_adji_3 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND itc.reason_code      = ''' || cv_reason_123 || ''''
                    || '   AND adji_v.rcv_pay_div  = CASE '
                    || '                               WHEN itc.trans_qty >= ' ||  cn_zero
                    || '                                 THEN ''' || cv_min || ''''
                    || '                               WHEN itc.trans_qty <  ' ||  cn_zero
                    || '                                 THEN ''' || cv_one || ''''
                    || '                               ELSE adji_v.rcv_pay_div '
                    || '                             END '
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND xmrl.mov_line_id     = ijm.attribute1 '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_3:SQL
    lv_sql_adji_3 := lv_select_adji_3 || lv_select
                  || lv_from_adji_3   || lv_where_adji_3
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- �݌ɒ���(�َ��i�ڕ��o�A���̑����o)
    lv_select_adji_4 := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_4 := lv_select_adji_4
                       || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                       || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_adji_4 := lv_select_adji_4
                       || ' NULL                 AS whse_code, '
                       || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_adji_4 := lv_select_adji_4
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- �������
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- �������
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- �����
                     || ' adji_v.dealings_div_name AS  div_name, ' -- ����敪��
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_adji_4 := ' FROM '
                   || ' ic_tran_cmp               itc, '       -- OPM�����݌Ƀg����
                   || ' ic_adjs_jnl               iaj, '       -- OPM�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst               ijm, '       -- OPM�W���[�i���}�X�^
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv, '      -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_lot_each_item_v     xleiv ';     -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_4 := lv_from_adji_4
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_adji_4 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND (( itc.reason_code   = ''' || cv_reason_942 || ''' )'
                    || '    OR  ( itc.reason_code   = ''' || cv_reason_951 || ''' ))'
                    || '   AND adji_v.rcv_pay_div  = CASE '
                    || '                               WHEN itc.trans_qty >= ' || cn_zero
                    || '                               THEN ''' || cv_one || ''''
                    || '                               ELSE ''' || cv_min || ''''
                    || '                             END '
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_2:SQL
    lv_sql_adji_4 := lv_select_adji_4 || lv_select
                  || lv_from_adji_4   || lv_where_adji_4
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- ============================================================================
    -- PROD reverse_id IS NULL
    -- ============================================================================
    lv_select_prod := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_prod := lv_select_prod
                     || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                     || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_prod := lv_select_prod
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_prod := lv_select_prod
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS trans_qty, '
                   || ' itp.trans_qty * TO_NUMBER(prod_v.rcv_pay_div) AS trans_qty, '
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS trans_date, '
                   || ' prod_v.dealings_div_name AS  div_name, ' -- ����敪��
                   || ' prod_v.rcv_pay_div     AS pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_prod := ' FROM '
                   || ' ic_tran_pnd                 itp, '
                   || ' ic_tran_pnd                 itp2, '
                   || ' xxcmn_rcv_pay_mst_prod_v    prod_v, '
                   || ' xxcmn_lookup_values2_v      xlvv, '    -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_lookup_values2_v      xlvv2, '
                   || ' xxcmn_lot_each_item_v       xleiv, '   -- ���b�g�ʕi�ڏ��view
                   || ' xxcmn_lot_each_item_v       xleiv2 ';  -- ���b�g�ʕi�ڏ��view
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_prod := lv_from_prod
                   || ' , ic_whse_mst         iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_prod := ' WHERE '
                  || ' itp.doc_type        = ''' || cv_prod || ''''
                  || ' AND itp.reverse_id      IS NULL '
                  || ' AND itp.doc_type        = prod_v.doc_type '
                  || ' AND itp.line_type       = prod_v.line_type '
                  || ' AND itp.doc_id          = prod_v.doc_id '
                  || ' AND itp.doc_line        = prod_v.doc_line '
                  || ' AND itp2.line_type      = CASE '
                  || '                             WHEN itp.line_type = ' || cn_min
                  || '                             THEN ' || cn_one
                  || '                             WHEN itp.line_type = ' || cn_one
                  || '                             THEN ' || cn_min
                  || '                           END '
                  || ' AND itp2.completed_ind  = ' || cn_one
                  || ' AND itp2.reverse_id     IS NULL '
                  || ' AND itp.doc_id          = itp2.doc_id '
                  || ' AND itp.doc_line        = itp2.doc_line '
                  || ' AND itp2.trans_date   >= FND_DATE.STRING_TO_DATE( '
                  || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                  || ' AND  itp2.trans_date   <= FND_DATE.STRING_TO_DATE('
                  || '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
                  || ' AND prod_v.dealings_div = ''' || cv_dealing_309 || '''' -- �i�ڐU��
                  || ' AND prod_v.dealings_div     = xlvv.meaning '
                  || ' AND itp2.item_id            = xleiv2.item_id '
                  || ' AND itp2.lot_id             = xleiv2.lot_id '
                  || ' AND ((xleiv2.start_date_active IS NULL) '
                  || '  OR  (xleiv2.start_date_active <= TRUNC(itp2.trans_date))) '
                  || ' AND ((xleiv2.end_date_active IS NULL) '
                  || '  OR  (xleiv2.end_date_active  >= TRUNC(itp2.trans_date))) '
                  || ' AND xleiv.item_div = CASE '
                  || '                         WHEN itp.line_type = ' || cn_min
                  || '                           THEN prod_v.item_div_origin '
                  || '                         WHEN itp.line_type = ' || cn_one
                  || '                           THEN prod_v.item_div_ahead '
                  || '                       END '
                  || ' AND xleiv2.item_div = CASE '
                  || '                         WHEN itp.line_type = ' || cn_one
                  || '                           THEN prod_v.item_div_origin '
                  || '                         WHEN itp.line_type = ' || cn_min
                  || '                           THEN prod_v.item_div_ahead '
                  || '                       END '
                  || ' AND prod_v.item_id  = itp.item_id '
                  || ' AND xlvv2.lookup_type          = '''  || cv_lookup2 || ''''
                  || ' AND xlvv2.meaning              = (''' || cv_meaning || ''' )'
                  || ' AND prod_v.dealings_div        = xlvv2.lookup_code '
                  || ' AND ((xlvv2.start_date_active IS NULL) '
                  || '  OR  (xlvv2.start_date_active <= TRUNC(itp.trans_date))) '
                  || ' AND ((xlvv2.end_date_active   IS NULL) '
                  || '  OR  (xlvv2.end_date_active    >= TRUNC(itp.trans_date))) ';
    -- PROD:SQL
    lv_sql_prod := lv_select_prod || lv_select
                || lv_from_prod   || lv_where_prod
                || lv_where_itp   || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- ============================================================================
    -- OMSO
    -- ============================================================================
    lv_select_omso := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_omso := lv_select_omso
                     || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                     || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_omso := lv_select_omso
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_omso := lv_select_omso
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- �������
                   || ' itp.trans_qty * TO_NUMBER(omso_v.rcv_pay_div) AS  trans_qty, '  -- �������
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- �����
                   || ' omso_v.dealings_div_name AS  div_name, ' -- ����敪��
                   || ' omso_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_omso := ' FROM '
                 || ' ic_tran_pnd               itp, '
                 || ' xxcmn_rcv_pay_mst_omso_v  omso_v, '
                 || ' xxcmn_lookup_values2_v    xlvv,  '   -- �N�C�b�N�R�[�h���VIEW2
                 || ' xxcmn_lot_each_item_v     xleiv  ';  -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_omso := lv_from_omso
                   || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_omso := ' WHERE '
                  || '        itp.doc_type         = ''' || cv_omso || ''''
                  || '   AND  itp.doc_type         = omso_v.doc_type '
                  || '   AND  itp.line_detail_id   = omso_v.doc_line '
                  || '   AND  omso_v.dealings_div  = xlvv.meaning ';
--
    -- OMSO:SQL
    lv_sql_omso := lv_select_omso || lv_select
                || lv_from_omso   || lv_where_omso
                || lv_where_itp   || lv_where;
--
    -- ============================================
    -- SELECT�吶��
    -- ============================================
    -- ============================================================================
    -- PORC
    -- ============================================================================
    lv_select_porc := ' SELECT ';
    -- ���[�敪���q��
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_porc := lv_select_porc
                     || ' iwm.whse_code        AS  whse_code, '   -- �q�ɃR�[�h
                     || ' iwm.whse_name        AS  whse_name, ';  -- �q�ɖ���
    ELSE
      lv_select_porc := lv_select_porc
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_porc := lv_select_porc
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- �������
                   || ' itp.trans_qty * TO_NUMBER(porc_v.rcv_pay_div) AS  trans_qty, '  -- �������
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- �����
                   || ' porc_v.dealings_div_name AS  div_name, ' -- ����敪��
                   || ' porc_v.rcv_pay_div     AS  pay_div, ';   -- �󕥋敪
--
    -- ============================================
    -- FROM�吶��
    -- ============================================
    lv_from_porc := ' FROM '
                 || ' ic_tran_pnd                     itp, '
                 || ' xxcmn_rcv_pay_mst_porc_rma03_v  porc_v, '
                 || ' xxcmn_lookup_values2_v          xlvv,  '   -- �N�C�b�N�R�[�h���VIEW2
                 || ' xxcmn_lot_each_item_v           xleiv  ';  -- ���b�g�ʕi�ڏ��View
--
    -- ���[�敪���q�ɕ�
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_porc := lv_from_porc
                   || ' , ic_whse_mst             iwm ';
    END IF;
--
    -- ============================================
    -- WHERE�吶��
    -- ============================================
    lv_where_porc := ' WHERE '
                  || '        itp.doc_type           = ''' || cv_porc || ''''
                  || '   AND  itp.doc_type           = porc_v.doc_type '
                  || '   AND  itp.doc_id             = porc_v.doc_id '
                  || '   AND  itp.doc_line           = porc_v.doc_line '
                  || '   AND  porc_v.dealings_div    = xlvv.meaning ';
--
    -- PORC:SQL
    lv_sql_porc := lv_select_porc || lv_select
                || lv_from_porc   || lv_where_porc
                || lv_where_itp   || lv_where;
--
    -- ===========================================================
    -- ORDER BY�吶��
    -- ===========================================================
    lv_order := ' ORDER BY ';
--
    -- �Q��ʂ�3�F�Q�ʂ̏ꍇ
    IF ( ir_param.crowd_type = cv_three ) THEN
--
      -- ���[��ʂ�1�F�q�ɕʁE�i�ڕʂ̏ꍇ
      IF ( ir_param.report_type = cv_one ) THEN
        lv_order := lv_order
                 || ' whse_code   ASC, '
                 || ' crowd_code  ASC, '
                 || ' item_code   ASC  ';
      -- ���[��ʂ�2�F�i�ڕʂ̏ꍇ
      ELSIF ( ir_param.report_type = cv_two ) THEN
        lv_order := lv_order
                 || ' crowd_code  ASC, '
                 || ' item_code   ASC  ';
      END IF;
    -- �Q��ʂ�4�F�o���Q�ʂ̏ꍇ
    ELSIF ( ir_param.crowd_type = cv_four ) THEN
--
      -- ���[��ʂ�1�F�q�ɕʁE�i�ڕʂ̏ꍇ
      IF ( ir_param.report_type = cv_one ) THEN
        lv_order := lv_order
                 || ' whse_code    ASC, '
                 || ' crowd_code   ASC, '
                 || ' item_code    ASC  ';
      -- ���[��ʂ�2�F�i�ڕʂ̏ꍇ
      ELSIF ( ir_param.report_type = cv_two ) THEN
        lv_order := lv_order
                 || ' crowd_code   ASC, '
                 || ' item_code    ASC  ';
      END IF;
    END IF;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql_xfer
           || ' UNION ALL ' || lv_sql_trni
           || ' UNION ALL ' || lv_sql_adji_1
           || ' UNION ALL ' || lv_sql_adji_2
           || ' UNION ALL ' || lv_sql_adji_3
           || ' UNION ALL ' || lv_sql_adji_4
           || ' UNION ALL ' || lv_sql_prod
           || ' UNION ALL ' || lv_sql_omso
           || ' UNION ALL ' || lv_sql_porc || lv_order ;
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
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
--
--
--
  /********************************************************************************
  * Procedure Name      : prc_item_sum
  * Description         : �i�ږ��׉��Z����
  ********************************************************************************/
  PROCEDURE prc_item_sum(
    in_pos            IN   NUMBER,       --   �i�ڃ��R�[�h�z��ʒu
    in_unit_price     IN   NUMBER,       --   ����
    ov_errbuf         OUT  VARCHAR2,     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT  VARCHAR2,     --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT  VARCHAR2      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_item_sum'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
    cv_one         CONSTANT VARCHAR2(1) := '1';
    cn_one         CONSTANT NUMBER := 1;
    cn_zero        CONSTANT NUMBER := 0;
    cn_min         CONSTANT NUMBER := -1;
    -- *** ���[�J���ϐ� ***
    ln_col_pos     NUMBER DEFAULT 0;  --�󕥋敪���̈󎚈ʒu���l
    ln_instr       NUMBER DEFAULT 0;
--
  BEGIN
--
    -- �󎚈ʒu(�W�v��ʒu�j�𐔒l�֕ϊ�
    BEGIN
      ln_instr := INSTR( gt_main_data(in_pos).column_no, gv_haifn );
      IF ( ln_instr > cn_zero )  THEN    --�Q�ӏ�����
        -- ����敪 ��� = 1
        IF (gt_main_data(in_pos).pay_div = cv_one)  THEN
          ln_col_pos  :=  TO_NUMBER(SUBSTR(gt_main_data(in_pos).column_no,
                                                         cn_one, ln_instr - cn_one));
        ELSE
          ln_col_pos  :=  TO_NUMBER(SUBSTR( gt_main_data(in_pos).column_no, ln_instr + cn_one ));
        END IF;
      END IF;
    EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_col_pos :=  cn_zero;
    END;
--
    IF (( ln_col_pos >= cn_one )
      AND ( ln_col_pos <= gc_print_pos_max )) THEN
-- 2008/08/28 v1.8 UPDATE START
--      IF (gt_main_data(in_pos).pay_div = cv_one ) THEN
--      --���ʉ��Z
--        qty(ln_col_pos) :=  qty(ln_col_pos) + gt_main_data(in_pos).trans_qty;
--      ELSIF (gt_main_data(in_pos).div_name = gv_div_name ) THEN --�I�����̏ꍇ
--        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty);
--      ELSE
--        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty * cn_min);
      IF (gt_main_data(in_pos).div_name = gv_div_name ) THEN --�I�����̏ꍇ
        qty(ln_col_pos) :=  qty(ln_col_pos)
          + (gt_main_data(in_pos).trans_qty / gt_main_data(in_pos).pay_div);
      ELSE
        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty);
-- 2008/08/28 v1.8 UPDATE END
      --���z���Z
      END IF;
      IF ( gt_main_data(in_pos).cost_div = gc_cost_ac ) THEN
        IF ( gt_main_data(in_pos).pay_div = cv_one ) THEN
          amt(ln_col_pos) := amt(ln_col_pos)
                          + ( in_unit_price * gt_main_data(in_pos).trans_qty);
        ELSE
          amt(ln_col_pos) := amt(ln_col_pos)
                          + ( in_unit_price * gt_main_data(in_pos).trans_qty * cn_min);
        END IF;
      ELSE
        amt(ln_col_pos) := cn_zero;
      END IF;
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
  END prc_item_sum;
--
--
--
--
  /***********************************************************************************
  * Procedure Name     : prc_item_init
  * Description        : �i�ږ��׃N���A����
  ************************************************************************************/
  PROCEDURE prc_item_init (
    ov_errbuf     OUT VARCHAR2,                 --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                 --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_item_init'; -- �v���O������
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
    <<item_rec_clear>>
    FOR i IN 1 .. gc_print_pos_max LOOP
      qty(i) := 0;
      amt(i) := 0;
    END LOOP  item_rec_clear;
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
  END prc_item_init;
--
--
--
--
  /************************************************************************************
  * Procedure Name     : prc_create_xml_data
  * Description        : �w�l�k�f�[�^�쐬
  *************************************************************************************/
  PROCEDURE prc_create_xml_data(
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
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           CONSTANT VARCHAR2(100) := '*';            -- �����l
    lc_break_null           CONSTANT VARCHAR2(100) := '**';           -- �m�t�k�k����
--
    cn_one                  CONSTANT NUMBER := 1;
    cn_zero                 CONSTANT NUMBER := 0;
    cn_two                  CONSTANT NUMBER := 2;
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_whse_code            VARCHAR2(100) DEFAULT lc_break_init;  -- �q�ɃR�[�h
    lv_crowd_high           VARCHAR2(100) DEFAULT lc_break_init;  -- ��Q�R�[�h
    lv_crowd_mid            VARCHAR2(100) DEFAULT lc_break_init;  -- ���Q�R�[�h
    lv_crowd_low            VARCHAR2(100) DEFAULT lc_break_init;  -- ���Q�R�[�h
    lv_crowd_dtl            VARCHAR2(100) DEFAULT lc_break_init;  -- �Q�R�[�h
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init;  -- �i�ڃR�[�h
--
    -- �v�Z�p
    ln_i                    NUMBER       DEFAULT 0;              -- �J�E���^�[�p
    ln_pos                  NUMBER       DEFAULT 1;
    ln_price                NUMBER       DEFAULT 0;              -- �����p
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION;             -- �擾���R�[�h�Ȃ�
--
    -- ===============================
    -- XML�^�O�}������
    -- ===============================
    PROCEDURE prc_set_xml (
      ic_type              IN    CHAR,                    -- �^�O�^�C�v  T:�^�O
                                                          -- D:�f�[�^
                                                          -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                          -- Z:�f�[�^(NULL�̏ꍇ0�\��)
      iv_name              IN    VARCHAR2,                -- �^�O��
      iv_value             IN    VARCHAR2  DEFAULT NULL,  -- �^�O�f�[�^(�ȗ���
      in_lengthb           IN    NUMBER    DEFAULT NULL,  -- �������i�o�C�g�j(�ȗ���
      iv_index             IN    NUMBER    DEFAULT NULL   -- �C���f�b�N�X(�ȗ���
    )
    IS
      -- =====================================================
      -- ���[�U�[�錾��
      -- =====================================================
      -- *** ���[�J���萔 ***
--
      -- *** ���[�J���ϐ� ***
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
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value, cn_one, in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
--
--
    -- ============================
    -- ���׍��� �w�l�k�o��
    -- ============================
    PROCEDURE prc_xml_body_add (
      in_pos             IN  NUMBER,       --   �i�ڃ��R�[�h�z��ʒu
      in_price           IN  NUMBER        --   �i�ڌ���
    )
    IS
--
    BEGIN
      -- =====================================================
      -- ���׏o�͕ҏW
      -- =====================================================
      -- =========================================
      -- �i��ID
      -- =========================================
      IF ((qty(gc_hamaoka_num)    + qty(gc_rec_kind_num) + qty(gc_rec_whse_num)
           + qty(gc_rec_etc_num)  + qty(gc_resale_num)   + qty(gc_aband_num)
           + qty(gc_sample_num)   + qty(gc_admin_num)    + qty(gc_acnt_num)
           + qty(gc_dis_kind_num) + qty(gc_dis_whse_num) + qty(gc_dis_etc_num)
           + qty(gc_inv_he_num)) <> cn_zero ) THEN
        prc_set_xml('D', 'item_code',    gt_main_data(in_pos).item_code);
--
        -- =========================================
        -- �i�ږ���
        -- =========================================
        prc_set_xml('D', 'item_name', gt_main_data(in_pos).item_name, 20);
--
        -- ==================================================
        -- ���
        -- ==================================================
        -- =========================================
        -- �l��
        -- =========================================
        prc_set_xml('Z', 'hamaoka_qty',    qty(gc_hamaoka_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'hamaoka_amt',  qty(gc_hamaoka_num) * in_price);
        ELSE
          prc_set_xml('Z', 'hamaoka_amt',  amt(gc_hamaoka_num));
        END IF;
--
        -- =========================================
        -- �i��ړ�
        -- =========================================
        prc_set_xml('Z', 'rec_kind_qty',   qty(gc_rec_kind_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'rec_kind_amt',   qty(gc_rec_kind_num) * in_price);
        ELSE
          prc_set_xml('Z', 'rec_kind_amt',   amt(gc_rec_kind_num));
        END IF;
--
        -- =========================================
        -- �q�Ɉړ�
        -- =========================================
        prc_set_xml('Z', 'rec_whse_qty',   qty(gc_rec_whse_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'rec_whse_amt',   qty(gc_rec_whse_num) * in_price);
        ELSE
          prc_set_xml('Z', 'rec_whse_amt',   amt(gc_rec_whse_num));
        END IF;
--
        -- =========================================
        -- ���̑�
        -- =========================================
        prc_set_xml('Z', 'rec_etc_qty',    qty(gc_rec_etc_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'rec_etc_amt',    qty(gc_rec_etc_num) * in_price);
        ELSE
          prc_set_xml('Z', 'rec_etc_amt',    amt(gc_rec_etc_num));
        END IF;
--
        -- =========================================
        -- �󕥍��v
        -- =========================================
        prc_set_xml('Z', 'rec_total_qty',  qty(gc_hamaoka_num)
                                        +  qty(gc_rec_kind_num)
                                        +  qty(gc_rec_whse_num)
                                        +  qty(gc_rec_etc_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'rec_total_amt',  qty(gc_hamaoka_num)  * in_price
                                          +  qty(gc_rec_kind_num) * in_price
                                          +  qty(gc_rec_whse_num) * in_price
                                          +  qty(gc_rec_etc_num)  * in_price);
        ELSE
          prc_set_xml('Z', 'rec_total_amt',  amt(gc_hamaoka_num)
                                          +  amt(gc_rec_kind_num)
                                          +  amt(gc_rec_whse_num)
                                          +  amt(gc_rec_etc_num));
        END IF;
--
        -- ===================================================
        -- ���o
        -- ===================================================
        -- =========================================
        -- �]��
        -- =========================================
        prc_set_xml('Z', 'resale_qty',     qty(gc_resale_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'resale_amt',     qty(gc_resale_num) * in_price);
        ELSE
          prc_set_xml('Z', 'resale_amt',     amt(gc_resale_num) );
        END IF;
--
        -- =========================================
        -- �p�p
        -- =========================================
        prc_set_xml('Z', 'aband_qty',      qty(gc_aband_num) );
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'aband_amt' ,     qty(gc_aband_num) * in_price);
        ELSE
          prc_set_xml('Z', 'aband_amt' ,     amt(gc_aband_num) );
        END IF;
--
        -- =========================================
        -- ���{
        -- =========================================
        prc_set_xml('Z', 'sample_qty',     qty(gc_sample_num) );
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'sample_amt',     qty(gc_sample_num) * in_price);
        ELSE
          prc_set_xml('Z', 'sample_amt',     amt(gc_sample_num) );
        END IF;
--
        -- =========================================
        -- �������o
        -- =========================================
        prc_set_xml('Z', 'admin_qty',      qty(gc_admin_num) );
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'admin_amt',      qty(gc_admin_num)  * in_price);
        ELSE
          prc_set_xml('Z', 'admin_amt',      amt(gc_admin_num) );
        END IF;
--
        -- =========================================
        -- �o�����o
        -- =========================================
        prc_set_xml('Z', 'acnt_qty',       qty(gc_acnt_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'acnt_amt',       qty(gc_acnt_num) * in_price);
        ELSE
          prc_set_xml('Z', 'acnt_amt',       amt(gc_acnt_num) );
        END IF;
--
        -- =========================================
        -- �i��ړ�
        -- =========================================
        prc_set_xml('Z', 'dis_kind_qty',   qty(gc_dis_kind_num) );
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'dis_kind_amt',   qty(gc_dis_kind_num) * in_price);
        ELSE
          prc_set_xml('Z', 'dis_kind_amt',   amt(gc_dis_kind_num) );
        END IF;
--
        -- =========================================
        -- �q�Ɉړ�
        -- =========================================
        prc_set_xml('Z', 'dis_whse_qty',   qty(gc_dis_whse_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'dis_whse_amt',  qty(gc_dis_whse_num) * in_price);
        ELSE
          prc_set_xml('Z', 'dis_whse_amt',   amt(gc_dis_whse_num) );
        END IF;
--
        -- =========================================
        -- ���̑�
        -- =========================================
        prc_set_xml('Z', 'dis_etc_qty',    qty(gc_dis_etc_num) );
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'dis_etc_amt',    qty(gc_dis_etc_num)  * in_price);
        ELSE
          prc_set_xml('Z', 'dis_etc_amt',    amt(gc_dis_etc_num) );
        END IF;
--
        -- =========================================
        -- �I������
        -- =========================================
        prc_set_xml('Z', 'inv_he_qty',     qty(gc_inv_he_num));
--
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'inv_he_amt',     qty(gc_inv_he_num) * in_price);
        ELSE
          prc_set_xml('Z', 'inv_he_amt',     amt(gc_inv_he_num));
        END IF;
--
        -- =========================================
        -- ���o���v
        -- =========================================
        prc_set_xml('Z', 'dis_total_qty', qty(gc_resale_num)
                                        + qty(gc_aband_num)
                                        + qty(gc_sample_num)
                                        + qty(gc_admin_num)
                                        + qty(gc_acnt_num)
                                        + qty(gc_dis_kind_num)
                                        + qty(gc_dis_whse_num)
                                        + qty(gc_dis_etc_num)
                                        + qty(gc_inv_he_num));
        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
          prc_set_xml('Z', 'dis_total_amt', qty(gc_resale_num)   * in_price
                                          + qty(gc_aband_num)    * in_price
                                          + qty(gc_sample_num)   * in_price
                                          + qty(gc_admin_num)    * in_price
                                          + qty(gc_acnt_num)     * in_price
                                          + qty(gc_dis_kind_num) * in_price
                                          + qty(gc_dis_whse_num) * in_price
                                          + qty(gc_dis_etc_num)  * in_price
                                          + qty(gc_inv_he_num)   * in_price);
        ELSE
          prc_set_xml('Z', 'dis_total_amt', amt(gc_resale_num)
                                          + amt(gc_aband_num)
                                          + amt(gc_sample_num)
                                          + amt(gc_admin_num)
                                          + amt(gc_acnt_num)
                                          + amt(gc_dis_kind_num)
                                          + amt(gc_dis_whse_num)
                                          + amt(gc_dis_etc_num)
                                          + amt(gc_inv_he_num));
        END IF;
      END IF;
--
    END prc_xml_body_add;
--
--
--
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
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = cn_zero ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gv_report_id);
    -- ���{��
    prc_set_xml('D', 'output_date', TO_CHAR( gd_exec_date, gc_char_dt_format ));
    -- �S������
    prc_set_xml('D', 'charge_dept', gv_user_dept, 10);
    -- �S���Җ�
    prc_set_xml('D', 'agent', gv_user_name, 14);
    -- �����N
    prc_set_xml('D', 'process_year', SUBSTR(gv_exec_start,1,4));
    -- ������
    prc_set_xml('D', 'process_month', SUBSTR(gv_exec_start,6,2));
    -- ���i�敪
    prc_set_xml('D', 'commodity_div', ir_param.item_division);
    -- ���i�敪����
    prc_set_xml('D', 'commodity_div_name', gv_item_div_name, 20);
    -- �i�ڋ敪
    prc_set_xml('D', 'item_div', ir_param.art_division);
    -- �i�ڋ敪��
    prc_set_xml('D', 'item_div_name', gv_art_div_name, 20);
    -- ���[���
    prc_set_xml('D', 'report_type', ir_param.report_type);
    -- ���[��ʖ�
    prc_set_xml('D', 'report_type_name', gv_report_div_name, 20);
    -- �Q���
    prc_set_xml('D', 'crowd_type', ir_param.crowd_type);
    -- �Q��ʖ�
    prc_set_xml('D', 'crowd_type_name', gv_crowd_kind_name, 20);
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', '/user_info');
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- ���|�[�g�^�C�g��
    prc_set_xml('D', 'report_name', gv_print_name);
    -- -----------------------------------------------------
    -- �q�ɂk�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_locat');
--
    -- �z��ʒu�J�E���^�̏����l�ݒ�
    ln_i  := cn_one;
   --=========================================�����v
    <<total_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT)                                             LOOP
      lv_whse_code  :=  NVL(gt_main_data(ln_i).whse_code, lc_break_null);
      prc_set_xml('T', 'g_locat');
      prc_set_xml('D', 'whse_code', gt_main_data(ln_i).whse_code);
      prc_set_xml('D', 'whse_name', gt_main_data(ln_i).whse_name, 20);
      -- �q�ɋ敪�F�t���O
      IF (( ir_param.warehouse_code IS NOT NULL )
        OR ( ir_param.report_type = cn_two )) THEN
        prc_set_xml('D', 'whse_flg', cn_zero);
      ELSE
        prc_set_xml('D', 'whse_flg', cn_one);
      END IF;
      prc_set_xml('D', 'position', ln_pos);
      prc_set_xml('T', 'lg_crowd_large');
      --=============================================�q�ɃR�[�h�J�n
      <<whse_code_loop>>
      WHILE (ln_i  <= gt_main_data.COUNT)
        AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)      LOOP
        lv_crowd_high  :=  NVL(gt_main_data(ln_i).crowd_large, lc_break_null);
        prc_set_xml('T', 'g_crowd_large');
        prc_set_xml('D', 'crowd_large_code', gt_main_data(ln_i).crowd_large);
        prc_set_xml('T', 'lg_crowd_medium');
        --===============================================��Q�R�[�h�J�n
        <<large_grp_loop>>
        WHILE (ln_i  <= gt_main_data.COUNT)
          AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)
          AND (NVL( gt_main_data(ln_i).crowd_large, lc_break_null ) = lv_crowd_high)     LOOP
          lv_crowd_mid  :=  NVL(gt_main_data(ln_i).crowd_medium, lc_break_null);
          prc_set_xml('T', 'g_crowd_medium');
          prc_set_xml('D', 'crowd_medium_code', gt_main_data(ln_i).crowd_medium);
          prc_set_xml('T', 'lg_crowd_small');
          --================================================���Q�R�[�h�J�n
          <<midle_grp_loop>>
          WHILE (ln_i  <= gt_main_data.COUNT)
            AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
            AND (NVL( gt_main_data(ln_i).crowd_medium, lc_break_null ) = lv_crowd_mid)       LOOP
            lv_crowd_low  :=  NVL(gt_main_data(ln_i).crowd_small, lc_break_null);
            prc_set_xml('T', 'g_crowd_small');
            prc_set_xml('D', 'crowd_small_code', gt_main_data(ln_i).crowd_small);
            prc_set_xml('T', 'lg_crowd_detail');
            --====================================================���Q�R�[�h�J�n
            <<minor_grp_loop>>
            WHILE (ln_i  <= gt_main_data.COUNT)
              AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
              AND (NVL( gt_main_data(ln_i).crowd_small, lc_break_null ) = lv_crowd_low)       LOOP
              lv_crowd_dtl  :=  NVL(gt_main_data(ln_i).crowd_code, lc_break_null);
              prc_set_xml('T', 'g_crowd_detail');
              prc_set_xml('D', 'crowd_detail_code', gt_main_data(ln_i).crowd_code);
              prc_set_xml('T', 'lg_line');
              --========================================================�Q�R�[�h�J�n
              <<grp_loop>>
              WHILE (ln_i  <= gt_main_data.COUNT)
                AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                AND (NVL( gt_main_data(ln_i).crowd_code, lc_break_null ) = lv_crowd_dtl)      LOOP
                lv_item_code  :=  NVL(gt_main_data(ln_i).item_code, lc_break_null);
                prc_set_xml('T', 'g_line');
                -- �i�ږ��׃N���A
                prc_item_init(
                  ov_errbuf     => lv_errbuf,
                  ov_retcode    => lv_retcode,
                  ov_errmsg     => lv_errmsg
                );
                IF ( lv_retcode = gv_status_error ) THEN
                  RAISE global_api_expt;
                END IF;
                -- �����擾
                ln_price := fnc_item_unit_pric_get (
                              in_pos   =>   ln_i
                            );
                --==========================================================�i�ڊJ�n
                <<item_loop>>
                WHILE (( ln_i  <= gt_main_data.COUNT )
                  AND  ( NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code )
                  AND  ( NVL( gt_main_data(ln_i).item_code, lc_break_null ) = lv_item_code ))  LOOP
                  -- �i�ږ��׉��Z����
                  prc_item_sum (
                    in_pos         => ln_i,
                    in_unit_price  => ln_price,
                    ov_errbuf      => lv_errbuf,
                    ov_retcode     => lv_retcode,
                    ov_errmsg      => lv_errmsg
                  );
                  IF ( lv_retcode = gv_status_error ) THEN
                    RAISE global_api_expt;
                  END IF;
                  -- �����׈ʒu
                  ln_i  :=  ln_i  + cn_one;
                END LOOP  item_loop;--======================================�i�ڏI��
                -- �i�ږ��ׂw�l�k�o��
                prc_xml_body_add (
                  in_pos        => ln_i - cn_one,
                  in_price      => ln_price
                );
                IF ( lv_retcode = gv_status_error ) THEN
                  RAISE global_api_expt;
                END IF;
                prc_set_xml('T', '/g_line');
              END LOOP  grp_loop;--=====================================�Q�R�[�h�I��
              prc_set_xml('T', '/lg_line');
              prc_set_xml('T', '/g_crowd_detail');
            END LOOP  minor_grp_loop;--===========================���Q�R�[�h�I��
            prc_set_xml('T', '/lg_crowd_detail');
            prc_set_xml('T', '/g_crowd_small');
          END LOOP  midle_grp_loop;--========================���Q�R�[�h�I��
          prc_set_xml('T', '/lg_crowd_small');
          prc_set_xml('T', '/g_crowd_medium');
        END LOOP  large_grp_loop;--======================��Q�R�[�h�I��
        prc_set_xml('T', '/lg_crowd_medium');
        prc_set_xml('T','/g_crowd_large');
      END LOOP  whse_code_loop;--====================�q�Ɍv�I��
      prc_set_xml('T','/lg_crowd_large');
      prc_set_xml('T','/g_locat');
      ln_pos := ln_pos + cn_one;
    END LOOP  total_loop;--====================�����v(ALL END)
--
    prc_set_xml('T', '/lg_locat');
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
  -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
  END prc_create_xml_data;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain (
    iv_process_year       IN    VARCHAR2,  -- �����N��
    iv_item_division      IN    VARCHAR2,  -- ���i�敪
    iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
    iv_report_type        IN    VARCHAR2,  -- ���|�[�g�敪
    iv_warehouse_code     IN    VARCHAR2,  -- �q�ɃR�[�h
    iv_crowd_type         IN    VARCHAR2,  -- �Q���
    iv_crowd_code         IN    VARCHAR2,  -- �Q�R�[�h
    iv_account_code       IN    VARCHAR2,  -- �o���Q�R�[�h
    ov_errbuf             OUT   VARCHAR2,  -- �G���[�E���b�Z�[�W            # �Œ� #
    ov_retcode            OUT   VARCHAR2,  -- ���^�[���E�R�[�h              # �Œ� #
    ov_errmsg             OUT   VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
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
    ld_year                 DATE;
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
    gv_report_id                := 'XXCMN770003T';      -- ���[ID
    gd_exec_date                := SYSDATE;            -- ���{��
    -- �p�����[�^�i�[
    -- ������
    lr_param_rec.process_year   := iv_process_year;
    lr_param_rec.item_division  := iv_item_division;
    lr_param_rec.art_division   := iv_art_division;
    lr_param_rec.report_type    := iv_report_type;
    lr_param_rec.warehouse_code := iv_warehouse_code;
    lr_param_rec.crowd_type     := iv_crowd_type;
    lr_param_rec.crowd_code     := iv_crowd_code;
    lr_param_rec.account_code   := iv_account_code;
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
    IF (( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn )) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <report_name>' || gv_print_name || '</report_name>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <whse_flg>1</whse_flg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <lg_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <lg_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <g_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <lg_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <g_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <lg_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <g_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <msg>' || lv_errmsg || '</msg>' );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </g_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </lg_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </g_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </lg_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </g_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </lg_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </lg_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
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
        lv_xml_string := fnc_conv_xml (
                           iv_name   => gt_xml_data_table(i).tag_name,    -- �^�O�l�[��
                           iv_value  => gt_xml_data_table(i).tag_value,   -- �^�O�f�[�^
                           ic_type   => gt_xml_data_table(i).tag_type     -- �^�O�^�C�v
                         );
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
--
  END submain ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main (
    errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
    retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
    iv_process_year       IN    VARCHAR2,  -- �����N��
    iv_item_division      IN    VARCHAR2,  -- ���i�敪
    iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
    iv_report_type        IN    VARCHAR2,  -- ���|�[�g�敪
    iv_warehouse_code     IN    VARCHAR2,  -- �q�ɃR�[�h
    iv_crowd_type         IN    VARCHAR2,  -- �Q���
    iv_crowd_code         IN    VARCHAR2,  -- �Q�R�[�h
    iv_account_code       IN    VARCHAR2   -- �o���Q�R�[�h
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
      iv_process_year        =>  iv_process_year,     -- �����N��
      iv_item_division       =>  iv_item_division,    -- ���i�敪
      iv_art_division        =>  iv_art_division,     -- �i�ڋ敪
      iv_report_type         =>  iv_report_type,      -- ���[���
      iv_warehouse_code      =>  iv_warehouse_code,   -- �q�ɃR�[�h
      iv_crowd_type          =>  iv_crowd_type,       -- �Q���
      iv_crowd_code          =>  iv_crowd_code,       -- �Q�R�[�h
      iv_account_code        =>  iv_account_code,     -- �o���Q�R�[�h
      ov_errbuf              =>  lv_errbuf,           -- �G���[�E���b�Z�[�W            # �Œ� #
      ov_retcode             =>  lv_retcode,          -- ���^�[���E�R�[�h              # �Œ� #
      ov_errmsg              =>  lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    );
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
END xxcmn770003c ;
/
