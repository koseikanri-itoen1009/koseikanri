CREATE OR REPLACE PACKAGE XXCOP006A011C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A011C(spec)
 * Description      : �����v��
 * MD.050           : �����v�� MD050_COP_006_A01
 * Version          : 3.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   Y.Goto           �V�K�쐬
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367�Ή�
 *  2009/04/14    1.2   Y.Goto           T1_0539,T1_0541�Ή�
 *  2009/04/28    1.3   Y.Goto           T1_0846,T1_0920�Ή�
 *  2009/06/12    1.4   Y.Goto           T1_1394�Ή�
 *  2009/07/13    2.0   Y.Goto           0000669�Ή�(���ʉۑ�IE479)
 *  2009/11/30    3.0   Y.Goto           I_E_479_019(�����v��p���������Ή��A�A�v��PT�Ή��A�v���O����ID�̕ύX)
 *  2010/02/03    3.1   Y.Goto           E_�{�ғ�_01222
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2                 --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                OUT    VARCHAR2                 --   �G���[�R�[�h     #�Œ�#
    ,iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver3.1_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver3.1_E_�{�ғ�_01222_SCS.Goto_ADD_END
  );
END XXCOP006A011C;
/
