CREATE OR REPLACE PACKAGE BODY XXWSH420003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420003C(body)
 * Description      : �o�׈˗�/�o�׎��э쐬�����N������
 * MD.050           : �o�׎��� T_MD050_BPO_420
 * MD.070           : �o�׈˗��o�׎��э쐬���� T_MD070_BPO_42C
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_sql_pattern      �����p�^�[���`�F�b�N
 *  fwd_sql_create         A-2 SQL���쐬
 *  get_demand_inf_fwd     A-3 �ړ��pSQL���쐬
 *  check_parameter        A-1  ���̓p�����[�^�`�F�b�N
 *  release_lock           ���b�N��������
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15   1.0  Oracle �k�������v   �V�K�쐬
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
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
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt              EXCEPTION;     -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXWSH420003C';       -- �p�b�P�[�W��
  --���b�Z�[�W�ԍ�
--  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- �p�����[�^������
--  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- �p�����[�^����
--  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo�t�]
--  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- �p�����[�^����
  gv_msg_xxcmn10135    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- �v���̔��s���s�G���[
  --�萔
  gv_mst_normal        CONSTANT VARCHAR2(10)  := '����I��';
  gv_mst_warn          CONSTANT VARCHAR2(10)  := '�x���I��';
  gv_mst_error         CONSTANT VARCHAR2(10)  := '�ُ�I��';
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '���i�敪';
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- ���b�Z�[�W�敪XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- ���b�Z�[�W�敪XXCMN
  -- �N�C�b�N�R�[�h�l
  gv_order_status_04   CONSTANT VARCHAR2(15)  := '04';                 -- �o�׎��ьv��ς�(�o��)
  gv_order_status_08   CONSTANT VARCHAR2(15)  := '08';                 -- �o�׎��ьv��ς�(�x��)
  gv_yes               CONSTANT VARCHAR2(1)   := 'Y';                  -- YES_NO�敪�iYES)
  gv_no                CONSTANT VARCHAR2(1)   := 'N';                  -- YES_NO�敪�iNO)
  gv_document_type_10  CONSTANT VARCHAR2(15)  := '10';                 -- �o�׈˗�
  gv_document_type_30  CONSTANT VARCHAR2(15)  := '30';                 -- �x���w��
  gv_record_type_20    CONSTANT VARCHAR2(15)  := '20';                 -- �o�Ɏ���
  gv_ship_class_1      CONSTANT VARCHAR2(15)  := '1';                  -- �o�׈˗�
  gv_ship_class_2      CONSTANT VARCHAR2(15)  := '2';                  -- �x���˗�
  gv_ship_class_3      CONSTANT VARCHAR2(15)  := '3';                  -- �q�֕ԕi
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- �t���O 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- �t���O 'N'
--  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '�o�ɓ�From';
--  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '�o�ɓ�To';
--  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '�o�׈˗�'
--  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '�ړ��w��'(�����^�C�v)
--  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '�o�׈˗�'
--  gv_cons_input_param  CONSTANT VARCHAR2(100) := '���̓p�����[�^�l';   -- '���̓p�����[�^�l'
--  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- �u�m��ʒm�ρv
--  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- �u���ߍς݁v
--  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- �u���b�g�Ǘ��i�v
--  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- �u���i�v
--  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- �u�ϑ�����v
--  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- �u�������v
--  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- �u�˗��ρv
--  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '�󒍖��׃A�h�I��';
--  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '�ړ��˗�/�w������(�A�h�I��)';
--  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- ���ʊ֐��ł̃G���[
--  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- �u������v
--  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- �u���������v
--  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- �u�w���v
--  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- ���i�敪�E�h�����N
--  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- ���i�敪�E���[�t
--  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '�o�׌�';             -- �o�׌�
--  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '�o�׌`��';           -- �o�׌`��^
--  gv_cons_number       CONSTANT VARCHAR2(50)  := '���l';               -- ���l^
  --�g�[�N��
--  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- �p�����[�^
--  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- �p�����[�^
--  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- �p�����[�^��
--  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- �����^�C�v
--  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- �e�[�u��
--  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- �G���[�R�[�h
--  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
--  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- �z����
--  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- �i��
--  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ���b�gNo
--  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- �˗�No/�ړ��ԍ�_�敪
--  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- ������
--  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- �ܖ�����
--  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- �ŗL�L��
--  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- �˗�No
--  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- �i�ڃR�[�h
--  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- �t�]���t
--  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- ���ד��t
--  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- �z����
--  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- ����t
--  gv_request_name_ship CONSTANT VARCHAR2(15)  := '�˗�No';             -- �˗�No
--  gv_request_name_move CONSTANT VARCHAR2(15)  := '�ړ��ԍ�';           -- �ړ��ԍ�
--  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '�z����';             -- �z����
--  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '���ɐ�';             -- ���ɐ�
  --�v���t�@�C��
--  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- �o��
--  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- �ړ�
--  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- ���_
--  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
--  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_total_cnt         NUMBER :=0;       -- �Ώی���
--  gd_yyyymmdd_from     DATE;             -- ���̓p�����[�^�o�ɓ�From
--  gd_yyyymmdd_to       DATE;             -- ���̓p�����[�^�o�ɓ�To
--  gv_yyyymmdd_from     VARCHAR2(10);     -- ���̓p�����[�^�o�ɓ�From
--  gv_yyyymmdd_to       VARCHAR2(10);     -- ���̓p�����[�^�o�ɓ�To
  gn_login_user        NUMBER;           -- ���O�C��ID
  gn_created_by        NUMBER;           -- ���O�C�����[�UID
  gn_conc_request_id   NUMBER;           -- �v��ID
  gn_prog_appl_id      NUMBER;           -- �A�v���P�[�V����ID
  gn_conc_program_id   NUMBER;           -- �v���O����ID
--  gt_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- ���i�敪
--
  -- �����ΏۂƂȂ�o�Ɍ����i�[����
  TYPE order_rec IS RECORD(
     deliver_from      xxwsh_order_headers_all.deliver_from%TYPE     -- �o�Ɍ�
   , total_cnt         NUMBER                                        -- ����
  );
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  order_tbl;
--
  /***********************************************************************************
   * Procedure Name   : get_order_info
   * Description      : �󒍃A�h�I�����擾
   ***********************************************************************************/
  PROCEDURE get_order_info(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_select1          VARCHAR2(32000) DEFAULT NULL;
    lv_select2          VARCHAR2(32000) DEFAULT NULL;
    lv_select_where     VARCHAR2(32000) DEFAULT NULL;
    lv_select_lock      VARCHAR2(32000) DEFAULT NULL;
    lv_select_order     VARCHAR2(32000) DEFAULT NULL;
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***       �󒍃A�h�I�����擾      ***
    -- ***************************************
    lv_select2 := 'SELECT xoha.deliver_from, '
        ||       '        COUNT(xoha.order_header_id) '
        ||       ' FROM   xxwsh_order_headers_all      xoha,'
        ||       '        xxcmn_cust_accounts_v        xcav,'
        ||       '        xxwsh_oe_transaction_types_v  xottv1,'
        ||       '        xxcmn_item_locations_v        xilv'
        ||       ' WHERE  xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')'
        ||       ' AND    xilv.segment1 = xoha.deliver_from'
        ||       ' AND    xcav.party_id = xoha.customer_id'
        ||       ' AND    xottv1.transaction_type_id = xoha.order_type_id'
        ||       ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||       ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))';
--
    lv_select2 := lv_select2 
        ||       ' AND EXISTS ('
        ||       ' SELECT xola.order_header_id'
        ||       ' FROM   xxwsh_order_lines_all xola,'
        ||       '        xxcmn_item_mst_v      ximv'
        ||       ' WHERE xola.order_header_id = xoha.order_header_id'
        ||       ' AND   NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND   ximv.item_no  = xola.shipping_item_code )'
        ||       ' GROUP BY xoha.deliver_from '
        ||       ' ORDER BY COUNT(xoha.order_header_id) DESC ';
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_select2);
    OPEN fwd_cur FOR lv_select2;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH fwd_cur BULK COLLECT INTO gr_demand_tbl;
--
    -- ���������̃Z�b�g
    gn_total_cnt := gr_demand_tbl.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE fwd_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_order_info;
--
  /**********************************************************************************
  * Procedure Name   : release_lock
  * Description      : ���b�N����
  ***********************************************************************************/
  PROCEDURE release_lock(
    in_reqid              IN NUMBER,                     -- �v��ID
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'release_lock';       -- �v���O������
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
    lv_strsql VARCHAR2(1000);
    lv_phase  VARCHAR2(5);
    lv_staus  VARCHAR2(1);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
        SELECT
            b.id1,
            a.sid,
            a.serial#,
            b.type,
            DECODE(b.lmode,1,'null', 2,'row share', 3,'row exclusive'
             ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
        FROM
            v$session a,
            v$lock b
        WHERE
            a.sid = b.sid
            AND (b.id1, b.id2) in 
                (SELECT d.id1, d.id2 FROM v$lock d 
                 WHERE d.id1=b.id1
                 AND d.id2=b.id2 AND d.request > 0) 
            AND b.id1 IN (SELECT bb.id1
                         FROM v$session aa, v$lock bb
                         WHERE aa.lockwait = bb.kaddr 
                         AND aa.module = 'XXWSH420004C')
            AND b.lmode = 6;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  LOOP
        EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
        BEGIN
            SELECT DECODE(fcr.phase_code,'C','Y','I','Y','N')
            INTO   lv_phase
            FROM   fnd_concurrent_requests fcr 
            WHERE  fcr.request_id = in_reqid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_phase := 'Y';
                NULL;
        END;
        FOR lock_rec IN lock_cur LOOP
          lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
          EXECUTE IMMEDIATE lv_strsql;
          lv_staus := '1';
        END LOOP;
  END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END release_lock;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf             OUT  NOCOPY   VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT  NOCOPY   VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT  NOCOPY   VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_conc_p_c   CONSTANT VARCHAR2(100) := 'COMPLETE';
    cv_conc_s_w   CONSTANT VARCHAR2(100) := 'WARNING';
    cv_conc_s_e   CONSTANT VARCHAR2(100) := 'ERROR';
    cv_param_all  CONSTANT VARCHAR2(100) := 'ALL';
    cv_param_0    CONSTANT VARCHAR2(100) := '0';
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    lc_out_param     VARCHAR2(1000);   -- ���̓p�����[�^�̏������ʃ��|�[�g�o�͗p
--
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
--    lv_lot_biz_class VARCHAR2(1);      -- ���b�g�t�]�������
--    ln_result        NUMBER;           -- ��������(0:����A1:�ُ�)
--    ld_standard_date DATE;             -- ����t
    i                INTEGER := 0;
    TYPE reqid_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    reqid_rec reqid_tab;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
--
    -- ===============================================
    --   �����Ώۃf�[�^�擾
    -- ===============================================
    get_order_info(    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    --   �o�Ɍ����[�v
    -- ===============================================
    <<demand_inf_loop>>
    FOR ln_d_cnt IN 1..gn_total_cnt LOOP
      i := i + 1;
      gn_target_cnt := gn_target_cnt + 1;
      reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                         application       => 'XXWSH'                              -- �A�v���P�[�V�����Z�k��
                       , program           => 'XXWSH420004C'                       -- �v���O������
                       , argument1         => NULL                                 -- �u���b�N
                       , argument2         => gr_demand_tbl(ln_d_cnt).deliver_from -- �o�Ɍ�
                       , argument3         => NULL                                 -- �˗�No
                         );
      -- �G���[�̏ꍇ
      IF ( reqid_rec(i) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_cons_msg_kbn_cmn
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_others_expt;
      ELSE
        COMMIT;
      END IF;
       -- �G���[����
       IF ( lv_retcode = gv_status_error ) THEN
           gn_error_cnt := 1;
           RAISE global_process_expt;
       END IF;
--
    END LOOP demand_inf_loop; -- �o�Ɍ����[�v�I���
--
/*
    -- ===============================================
    -- ���b�N�b��Ή�
    -- ===============================================
    <<lock_loop>>
    FOR k IN 1 .. i LOOP
            -- �q�v���ɂ��ă��b�N�Ŏ~�܂��Ă�����̂�i�߂�
            release_lock(reqid_rec(k)
                      , lv_errbuf
                      , lv_retcode
                      , lv_errmsg);
    END LOOP lock_loop; -- ���b�N�J�����[�v�I���
*/
--
    -- ===============================================
    -- A-5  �R���J�����g�X�e�[�^�X�̃`�F�b�N
    -- ===============================================
    <<chk_status>>
    FOR j IN 1 .. i LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             request_id => reqid_rec(j)
            ,interval   => 1
            ,max_wait   => 0
            ,phase      => lv_phase
            ,status     => lv_status
            ,dev_phase  => lv_dev_phase
            ,dev_status => lv_dev_status
            ,message    => lv_errbuf
            ) ) THEN
        -- �X�e�[�^�X���f
        -- �t�F�[�Y:����
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
          -- �X�e�[�^�X:�ُ�
          IF ( lv_dev_status = cv_conc_s_e ) THEN
            ov_retcode := gv_status_error;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�Ɍ�:' || gr_demand_tbl(j).deliver_from || '�A����:' || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_error);
            gn_error_cnt := gn_error_cnt + 1;
          -- �X�e�[�^�X:�x��
          ELSIF ( lv_dev_status = cv_conc_s_w ) THEN
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := gv_status_warn;
            END IF;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�Ɍ�:' || gr_demand_tbl(j).deliver_from || '�A����:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_warn);
            gn_warn_cnt := gn_warn_cnt + 1;
          -- �X�e�[�^�X:����
          ELSE
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'�o�Ɍ�:' || gr_demand_tbl(j).deliver_from || '�A����:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '���A�v��ID�F' || TO_CHAR(reqid_rec(j)) || '�A�������ʁF' || gv_msg_part || gv_mst_normal);
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
        END IF;
      ELSE
        ov_retcode := gv_status_error;
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j)) || gv_msg_part || gv_mst_error);
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
    END LOOP chk_status;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT NOCOPY   VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT NOCOPY   VARCHAR2       -- ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_deliver_from_id   NUMBER; -- �o�Ɍ�
    ln_deliver_type      NUMBER; -- �o�Ɍ`��
--
  BEGIN
--
    -- ���l�^�ɕϊ�����
    lv_retcode         := gv_cons_flg_yes;
    lv_retcode         := gv_cons_flg_no;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    -- WHO�J�������̎擾
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ���O�C��ID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ���O�C�����[�UID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �R���J�����g�E�v���O����ID
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_warn_cnt   := 0;   -- �x������
    gn_error_cnt  := 0;   -- �G���[����
--
    submain(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      IF ( lv_errmsg IS NULL ) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00008', 'CNT', TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00009', 'CNT', TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00010', 'CNT', TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    --gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00011', 'CNT', TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�x�������F ' || TO_CHAR(gn_warn_cnt) || ' ��');
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
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
END XXWSH420003C;
/
