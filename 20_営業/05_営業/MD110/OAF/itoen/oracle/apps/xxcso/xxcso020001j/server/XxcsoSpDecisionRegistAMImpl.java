/*============================================================================
* �t�@�C���� : XxcsoSpDecisionRegistAMImpl
* �T�v����   : SP�ꌈ�o�^��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.7
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS����_     �V�K�쐬
* 2009-03-04 1.1  SCS����_     �ۑ�ꗗNo.73�Ή�
* 2009-03-23 1.2  SCS�������l   [ST��QT1_0163]�ۑ�No.115��荞��
* 2009-04-14 1.3  SCS�������l   [ST��QT1_0225]�_���validate�C��
* 2009-04-27 1.4  SCS�������l   [ST��QT1_0294]�����ʏ����m�莖�����f�C��
* 2009-08-04 1.5  SCS����_     [SCS��Q0000908]�R�s�[���̉񑗐�Đݒ�Ή�
* 2009-08-24 1.6  SCS�������   [SCS��Q0001104]�\���敪�`�F�b�N�Ή�
* 2009-10-14 1.7  SCS�������   [���ʉۑ�IE554,IE573]�Z���Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoBusinessCondTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoExtRefOpclTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoBusinessTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionInitUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionPropertyUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionReflectUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionValidateUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionCalculateUtils;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;

/*******************************************************************************
 * SP�ꌈ���̓o�^���s�����߂�
 * �A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionRegistAMImpl()
  {
  }

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏������i�ڍׁj����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_ID
   *****************************************************************************
   */
  public void initDetails(
    String spDecisionHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �g�����U�N�V�������N���A����
    rollback();

    // �g�p����C���X�^���X���擾����    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecisionSendInitVOImpl sendInitVo
      = getXxcsoSpDecisionSendInitVO1();
    if ( sendInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendInitVO1"
        );
    }
    
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecRequestFullVO1"
        );
    }

    ///////////////////////////////////////////
    // �{����
    ///////////////////////////////////////////    
    initVo.executeQuery();
    sendInitVo.executeQuery();
    
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    // �w�b�_�̌���
    headerVo.initQuery(spDecisionHeaderId);

    if ( spDecisionHeaderId == null || "".equals(spDecisionHeaderId) )
    {
      ///////////////////////////////////////
      // �g�����U�N�V�����̏�����
      ///////////////////////////////////////
      XxcsoSpDecisionInitUtils.initializeTransaction(
        txn
       ,null
       ,initRow.getBaseCode()
      );

      // �v���r���[�C���X�^���X�̏�����
      requestVo.executeQuery();
      
      ///////////////////////////////////////
      // �V�K���R�[�h�̏�����
      ///////////////////////////////////////
      XxcsoSpDecisionInitUtils.initializeRow(
        initVo
       ,sendInitVo
       ,headerVo
       ,installVo
       ,cntrctVo
       ,bm1Vo
       ,bm2Vo
       ,bm3Vo
       ,sendVo
      );
    }
    else
    {
      ///////////////////////////////////////
      // �g�����U�N�V�����̏�����
      ///////////////////////////////////////
      XxcsoSpDecisionHeaderFullVORowImpl headerRow
        = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
      
      XxcsoSpDecisionInitUtils.initializeTransaction(
        txn
       ,spDecisionHeaderId
       ,headerRow.getAppBaseCode()
      );      

      // �v���r���[�C���X�^���X�̏�����
      requestVo.executeQuery();
    }
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏������i�R�s�[�j����
   * @param spDecisionHeaderId SP�ꌈ�w�b�_ID
   *****************************************************************************
   */
  public void initCopyDetails(
    String spDecisionHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �g�����U�N�V�������N���A����
    rollback();

    // �g�p����C���X�^���X���擾����    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    ///////////////////////////////////////////
    // �R�s�[��p�C���X�^���X
    ///////////////////////////////////////////    
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecRequestFullVO1"
        );
    }

    ///////////////////////////////////////////
    // �R�s�[���p�C���X�^���X
    ///////////////////////////////////////////    
    XxcsoSpDecisionHeaderFullVOImpl headerVo2
      = getXxcsoSpDecisionHeaderFullVO2();
    if ( headerVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO2"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo2
      = getXxcsoSpDecisionInstCustFullVO2();
    if ( installVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO2"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo2
      = getXxcsoSpDecisionCntrctCustFullVO2();
    if ( cntrctVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO2"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo2
      = getXxcsoSpDecisionScLineFullVO2();
    if ( scVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO2"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo2
      = getXxcsoSpDecisionAllCcLineFullVO2();
    if ( allCcVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO2"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo2
      = getXxcsoSpDecisionSelCcLineFullVO2();
    if ( selCcVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO2"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo2
      = getXxcsoSpDecisionBm1CustFullVO2();
    if ( bm1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO2"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo2
      = getXxcsoSpDecisionBm2CustFullVO2();
    if ( bm2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO2"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo2
      = getXxcsoSpDecisionBm3CustFullVO2();
    if ( bm3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO2"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo2
      = getXxcsoSpDecisionAttachFullVO2();
    if ( attachVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO2"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo2
      = getXxcsoSpDecisionSendFullVO2();
    if ( sendVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO2"
        );
    }
    
// 2009-08-04 [��Q0000908] Add Start
    XxcsoSpDecisionSendInitVOImpl sendInitVo
      = getXxcsoSpDecisionSendInitVO1();
    if ( sendInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendInitVO1"
        );
    }
// 2009-08-04 [��Q0000908] Add End

    ///////////////////////////////////////////
    // �{����
    ///////////////////////////////////////////    
    initVo.executeQuery();
    
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    // �w�b�_�̌���
    headerVo.initQuery((String)null);
    headerVo2.initQuery(spDecisionHeaderId);

    ///////////////////////////////////////
    // �g�����U�N�V�����̏�����
    ///////////////////////////////////////
    XxcsoSpDecisionInitUtils.initializeTransaction(
      txn
     ,null
     ,initRow.getBaseCode()
    );

    ///////////////////////////////////////
    // �R�s�[����
    ///////////////////////////////////////
    XxcsoSpDecisionInitUtils.initializeCopyRow(
      initVo
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
     ,headerVo2
     ,installVo2
     ,cntrctVo2
     ,bm1Vo2
     ,bm2Vo2
     ,bm3Vo2
     ,scVo2
     ,allCcVo2
     ,selCcVo2
     ,attachVo2
     ,sendVo2
// 2009-08-04 [��Q0000908] Add Start
     ,sendInitVo
// 2009-08-04 [��Q0000908] Add End
    );
    
    // �v���r���[�C���X�^���X�̏�����
    requestVo.executeQuery();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �K�p�{�^����������
   *****************************************************************************
   */
  public HashMap handleApplyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }
    
    List errorList = new ArrayList();
    
    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    headerRow.setStatus(XxcsoSpDecisionConstants.STATUS_INPUT);
    requestRow.setOperationMode(null);

    validateAll(false);
    
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * ��o�{�^����������
   *****************************************************************************
   */
  public HashMap handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_SUBMIT);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SUBMIT
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * �m�F�{�^����������
   *****************************************************************************
   */
  public HashMap handleConfirmButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_CONFIRM);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONFIRM
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * �ԋp�{�^����������
   *****************************************************************************
   */
  public HashMap handleReturnButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_RETURN);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_RETURN
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * ���F�{�^����������
   *****************************************************************************
   */
  public HashMap handleApproveButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_APPROVE);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_APPROVE
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * �ی��{�^����������
   *****************************************************************************
   */
  public HashMap handleRejectButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_REJECT);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_REJECT
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * �����˗��{�^����������
   *****************************************************************************
   */
  public HashMap handleRequestButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    // 2009-08-24 [��Q0001104] Add Start
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
   
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_REQUEST);
    // 2009-08-24 [��Q0001104] Add End

    validateAll(true);

    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    NUMBER requestId = null;
    OracleCallableStatement stmt = null;
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := fnd_request.submit_request(");
      sql.append("          application       => 'XXCSO'");
      sql.append("         ,program           => 'XXCSO020A04C'");
      sql.append("         ,description       => NULL");
      sql.append("         ,start_time        => NULL");
      sql.append("         ,sub_request       => FALSE");
      sql.append("         ,argument1         => :2");
      sql.append("       );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getSpDecisionHeaderId().stringValue());

      stmt.execute();
      
      requestId = stmt.getNUMBER(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    if ( NUMBER.zero().equals(requestId) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(50);
        sql.append("BEGIN fnd_message.retrieve(:1); END;");

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.VARCHAR);

        stmt.execute();

        String errmsg = stmt.getString(1);

        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00310
           ,XxcsoConstants.TOKEN_CONC
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
           ,XxcsoConstants.TOKEN_CONCMSG
           ,errmsg
          );
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
          );
      }
      finally
      {
        try
        {
          if ( stmt != null )
          {
            stmt.close();
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
        }
      }
    }

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_REQUEST_CONC
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
            + requestId.stringValue()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_START
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * �ݒu��Ɠ����`�F�b�N�{�b�N�X�̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleSameInstallAccountFlagChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectContract(
      installVo
     ,cntrctVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * ��������I���̕ύX�C�x���g����
   * �S�e��敪�̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleConditionBusinessTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    XxcsoSpDecisionCcLineInitVOImpl ccLineInitVo
      = getXxcsoSpDecisionCcLineInitVO1();
    if ( ccLineInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCcLineInitVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectConditionBusiness(
      headerVo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,ccLineInitVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �����ʏ����̍s�ǉ��{�^����������
   *****************************************************************************
   */
  public void handleScAddRowButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionScLineFullVOImpl scVo = getXxcsoSpDecisionScLineFullVO1();

    int lineSize = scVo.getRowCount();
    String maxLineSizeStr = txn.getProfile("XXCSO1_VIEW_SIZE_020_A01_01");

    if ( lineSize == Integer.parseInt(maxLineSizeStr) )
    {
      throw
        XxcsoMessage.createMaxRowException(
          XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_COND
         ,maxLineSizeStr
        );
    }
    
    scVo.last();
    scVo.next();
    scVo.insertRow(scVo.createRow());
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �����ʏ����̍s�폜�{�^����������
   *****************************************************************************
   */
  public void handleScDelRowButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    boolean existFlag = false;
    
    while ( scRow != null )
    {
      if ( "Y".equals(scRow.getSelectFlag()) )
      {
        existFlag = true;
        scVo.removeCurrentRow();
      }

      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( ! existFlag )
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00290
        );
    }

    scVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * �艿���Z���v�Z�i�����ʏ����j�{�^����������
   *****************************************************************************
   */
  public void handleScCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateScLine(
        txn
       ,headerVo
       ,scVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateSalesCondition(
      txn
     ,headerVo
     ,scVo
    );

    scVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �艿���Z���v�Z�i�S�e��ꗥ�����j�{�^����������
   *****************************************************************************
   */
  public void handleAllCcCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateAllCcLine(
        txn
       ,headerVo
       ,allCcVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateAllCcCondition(
      txn
     ,headerVo
     ,allCcVo
    );

    allCcVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �艿���Z���v�Z�i�e��ʏ����j�{�^����������
   *****************************************************************************
   */
  public void handleSelCcCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateSelCcLine(
        txn
       ,headerVo
       ,selCcVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateSelCcCondition(
      txn
     ,headerVo
     ,selCcVo
    );

    selCcVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ���t��̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleBm1SendTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBmFormatVOImpl bmFmtVo
      = getXxcsoSpDecisionBmFormatVO1();
    if ( bmFmtVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBmFormatVO1"
        );
    }
    
    XxcsoSpDecisionReflectUtils.reflectBm1(
      headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bmFmtVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �x�������E���׏��iBM1�j�̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleBm1PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
      
    String bm1SendType   = headerRow.getBm1SendType();
    String bmPaymentType = bm1Row.getBmPaymentType();
    String transferType  = bm1Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
      if ( transferType == null || "".equals(transferType) )
      {
        bm1Row.setTransferCommissionType(
          XxcsoSpDecisionConstants.TRANSFER_CUST
        );
      }
      
      if ( bm1SendType == null || "".equals(bm1SendType) )
      {
        headerRow.setBm1SendType(XxcsoSpDecisionConstants.SEND_OTHER);
      }

      handleBm1SendTypeChange();
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �x�������E���׏��iBM2�j�̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleBm2PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
      
    String bmPaymentType = bm2Row.getBmPaymentType();
    String transferType  = bm2Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
      if ( transferType == null || "".equals(transferType) )
      {
        bm2Row.setTransferCommissionType(
          XxcsoSpDecisionConstants.TRANSFER_CUST
        );
      }
    }

    XxcsoSpDecisionReflectUtils.reflectBm2(
      headerVo
     ,installVo
     ,bm2Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �x�������E���׏��iBM3�j�̕ύX�C�x���g����
   *****************************************************************************
   */
  public void handleBm3PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
      
    String bmPaymentType = bm3Row.getBmPaymentType();
    String transferType  = bm3Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
      if ( transferType == null || "".equals(transferType) )
      {
        bm3Row.setTransferCommissionType(
          XxcsoSpDecisionConstants.TRANSFER_CUST
        );
      }
    }

    XxcsoSpDecisionReflectUtils.reflectBm3(
      headerVo
     ,installVo
     ,bm3Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

// 2009-03-23 [ST��QT1_0163] Add Start
  /*****************************************************************************
   * �d�C��敪�ύX�C�x���g����
   *****************************************************************************
   */
  public void handleElectricityTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectElectricity(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }
// 2009-03-23 [ST��QT1_0163] Add End

  /*****************************************************************************
   * ��񔽉f�{�^����������
   *****************************************************************************
   */
  public void handleReflectContractButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    List errorList
      = XxcsoSpDecisionValidateUtils.validateOtherCondition(
          txn
         ,headerVo
         ,false
        );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoSpDecisionReflectUtils.reflectContent(
      headerVo
     ,installVo
     ,bm1Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �T�Z�N�ԑ��v�v�Z�{�^����������
   *****************************************************************************
   */
  public void handleCalcProfitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }
    
    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    List errorList = new ArrayList();
    String condBizType = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();

    /////////////////////////////////////
    // �l�̊m�F
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.validateScLine(
          txn
         ,headerVo
         ,scVo
         ,true
        )
      );

      scVo.first();
    }
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateAllCcLine(
            txn
           ,headerVo
           ,allCcVo
           ,true
          )
        );

        allCcVo.first();
      }
      else
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateSelCcLine(
            txn
           ,headerVo
           ,selCcVo
           ,true
          )
        );

        selCcVo.first();
      }
    }

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateEstimateProfit(
        txn
       ,headerVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    /////////////////////////////////////
    // ���׍s�̌v�Z
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      XxcsoSpDecisionCalculateUtils.calculateSalesCondition(
        txn
       ,headerVo
       ,scVo
      );

      scVo.first();
    }
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        XxcsoSpDecisionCalculateUtils.calculateAllCcCondition(
          txn
         ,headerVo
         ,allCcVo
        );

        allCcVo.first();
      }
      else
      {
        XxcsoSpDecisionCalculateUtils.calculateSelCcCondition(
          txn
         ,headerVo
         ,selCcVo
        );

        selCcVo.first();
      }
    }

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�̌v�Z
    /////////////////////////////////////
    XxcsoSpDecisionCalculateUtils.calculateEstimateYearProfit(
      txn
     ,headerVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �Y�t�ǉ��{�^����������
   *****************************************************************************
   */
  public void handleAttachAddButton(
    String     fileName
   ,BlobDomain fileData
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();
    
    // �C���X�^���X�擾
    XxcsoSpDecisionInitVOImpl initVo
      = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }
    
    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    String excerpt = initRow.getAttachFileUpExcerpt();
    
    // 2009-08-24 [��Q0001104] Add Start
    //if ( excerpt == null || "".equals(excerpt.trim()) )
    //{
    //  errorList.add(
    //    XxcsoMessage.createErrorMessage(
    //      XxcsoConstants.APP_XXCSO1_00005
    //     ,XxcsoConstants.TOKEN_COLUMN
    //     ,XxcsoSpDecisionConstants.TOKEN_VALUE_EXCERPT
    //    )
    //  );
    //}
    // 2009-08-24 [��Q0001104] Add End
    
    int fileNameLen = fileName.getBytes().length;
    int maxFileNameLen = XxcsoSpDecisionConstants.MAX_ATTACH_FILE_NAME_LENGTH;
      
    if ( fileNameLen > maxFileNameLen )
    {
      errorList.add(
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00074
         ,XxcsoConstants.TOKEN_COLUMN
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
         ,XxcsoConstants.TOKEN_EMSIZE
         ,String.valueOf(maxFileNameLen / 2)
         ,XxcsoConstants.TOKEN_ONEBYTE
         ,String.valueOf(maxFileNameLen)
        )
      );
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    attachVo.last();
    attachVo.next();
    
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.createRow();

    attachRow.setFileName(fileName);
    attachRow.setExcerpt(excerpt);
    attachRow.setFileData(fileData);
    attachRow.setFullName(initRow.getFullName());

    attachVo.insertRow(attachRow);

    String a = initRow.getAttachFileUp();

    initRow.setAttachFileUpExcerpt(null);
    // 2009-08-24 [��Q0001104] Add Start
    // �Y�t�t�@�C�����N���A
    initRow.setAttachFileUp(null);
    // 2009-08-24 [��Q0001104] Add End
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �Y�t�폜�{�^����������
   *****************************************************************************
   */
  public void handleAttachDelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();

    boolean existFlag = false;
    while ( attachRow != null )
    {
      if ( "Y".equals(attachRow.getSelectFlag()) )
      {
        existFlag = true;
        attachVo.removeCurrentRow();
      }

      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }

    if ( ! existFlag )
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00490
        );
    }
    
    attachVo.first();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �e�|�b�v���X�g�̏���������
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �\���敪
    XxcsoLookupListVOImpl appListVo
      = getXxcsoApplicationTypeListVO();
    if ( appListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoApplicationTypeListVO");
    }

    appListVo.initQuery(
      "XXCSO1_SP_APPLICATION_TYPE"
     ,"lookup_code"
    );
    
    // �X�e�[�^�X
    XxcsoLookupListVOImpl statusVo
      = getXxcsoStatusListVO();
    if ( statusVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoStatusListVO");
    }

    statusVo.initQuery(
      "XXCSO1_SP_STATUS_CD"
     ,"lookup_code"
    );
    
    // �Ƒԁi�����ށj
    XxcsoBusinessCondTypeListVOImpl businessCondListVo
      = getXxcsoBusinessCondTypeListVO();
    if ( businessCondListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBusinessCondTypeListVO");
    }
    businessCondListVo.clearCache();
    
    // �Ǝ�
    XxcsoBusinessTypeListVOImpl businessListVo
      = getXxcsoBusinessTypeListVO1();
    if ( businessListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBusinessTypeListVO1");
    }

    // �ݒu�ꏊ
    XxcsoLookupListVOImpl installLocVo
      = getXxcsoInstallLocationListVO();
    if ( installLocVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallLocationListVO");
    }

    installLocVo.initQuery(
      "XXCMM_CUST_VD_SECCHI_BASYO"
     ,"lookup_code"
    );
    
    // �I�[�v���E�N���[�Y
    XxcsoExtRefOpclTypeListVOImpl extRefOpclListVo
      = getXxcsoExtRefOpclTypeListVO();
    if ( extRefOpclListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoExtRefOpclTypeListVO");
    }

    // �V�^��
    XxcsoLookupListVOImpl newOldListVo
      = getXxcsoNewoldTypeListVO();
    if ( newOldListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoNewoldTypeListVO");
    }

    newOldListVo.initQuery(
      "XXCSO1_CSI_JOB_KBN"
     ,"attribute3 = '1'"
     ,"TO_NUMBER(lookup_code)"
    );
    
    // ���[�J�[�R�[�h
    XxcsoLookupListVOImpl makerCodeListVo
      = getXxcsoMakerCodeListVO();
    if ( makerCodeListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoMakerCodeListVO");
    }

    makerCodeListVo.initQuery(
      "XXCSO_CSI_MAKER_CODE"
     ,"lookup_code"
    );

    // �K�i���^�O
    XxcsoLookupListVOImpl standardListVo
      = getXxcsoStandardTypeListVO();
    if ( standardListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoStandardTypeListVO");
    }

    standardListVo.initQuery(
      "XXCSO1_SP_VD_STANDARD_TYPE"
     ,"lookup_code"
    );
    
    // �������
    XxcsoLookupListVOImpl condBizListVo
      = getXxcsoConditionBizTypeListVO();
    if ( condBizListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoConditionBizTypeListVO");
    }

    condBizListVo.initQuery(
      "XXCSO1_SP_BUSINESS_COND"
     ,"lookup_code"
    );

    // �艿
    XxcsoLookupListVOImpl fixedPriceListVo
      = getXxcsoFiexedPriceListVO();
    if ( fixedPriceListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoFiexedPriceListVO");
    }

    fixedPriceListVo.initQuery(
      "XXCSO1_SP_RULE_SELL_PRICE"
// 2009-04-27 [ST��QT1_0294] Mod Start
//     ,"lookup_code"
     ,"TO_NUMBER(lookup_code)"
// 2009-04-27 [ST��QT1_0294] Mod End
    );

    // �S�e��敪
    XxcsoLookupListVOImpl allContainerListVo
      = getXxcsoAllContainerTypeListVO();
    if ( allContainerListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAllContainerTypeListVO");
    }

    allContainerListVo.initQuery(
      "XXCSO1_SP_ALL_CONTAINER_TYPE"
     ,"lookup_code"
    );
    
    // �e��敪
    XxcsoLookupListVOImpl ruleBottleListVo
      = getXxcsoRuleBottleTypeListVO();
    if ( ruleBottleListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoRuleBottleTypeListVO");
    }

    ruleBottleListVo.initQuery(
      "XXCSO1_SP_RULE_BOTTLE"
     ,"attribute4"
    );
    
    // �d�C��
    XxcsoLookupListVOImpl electricityListVo
      = getXxcsoElectricityTypeListVO();
    if ( electricityListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoElectricityTypeListVO");
    }

    electricityListVo.initQuery(
      "XXCSO1_SP_ELECTRIC_BILL_TYPE"
     ,"lookup_code"
    );

    // ���t��
    XxcsoLookupListVOImpl bm1SendListVo
      = getXxcsoBm1SendTypeListVO();
    if ( bm1SendListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1SendTypeListVO");
    }

    bm1SendListVo.initQuery(
      "XXCSO1_SP_SEND_TO_TYPE"
     ,"lookup_code"
    );

    // �U���萔�����S�iBM1�j
    XxcsoLookupListVOImpl bm1TransferListVo
      = getXxcsoTransferTypeListVO1();
    if ( bm1TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO1");
    }

    bm1TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // �U���萔�����S�iBM2�j
    XxcsoLookupListVOImpl bm2TransferListVo
      = getXxcsoTransferTypeListVO2();
    if ( bm2TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO2");
    }

    bm2TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // �U���萔�����S�iBM3�j
    XxcsoLookupListVOImpl bm3TransferListVo
      = getXxcsoTransferTypeListVO3();
    if ( bm3TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO3");
    }

    bm3TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // �x�����׏��iBM1�j
    XxcsoLookupListVOImpl bm1PaymentListVo
      = getXxcsoBmPaymentTypeListVO1();
    if ( bm1PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO1");
    }

    bm1PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // �x�����׏��iBM2�j
    XxcsoLookupListVOImpl bm2PaymentListVo
      = getXxcsoBmPaymentTypeListVO2();
    if ( bm2PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO2");
    }

    bm2PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // �x�����׏��iBM3�j
    XxcsoLookupListVOImpl bm3PaymentListVo
      = getXxcsoBmPaymentTypeListVO3();
    if ( bm3PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO3");
    }

    bm3PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // �񑗐�I��͈�
    XxcsoLookupListVOImpl empAreaListVo
      = getXxcsoEmpAreaTypeListVO();
    if ( empAreaListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoEmpAreaTypeListVO");
    }

    empAreaListVo.initQuery(
      "XXCSO1_SP_EMPLOYEE_AREA"
     ,"lookup_code"
    );

    // ���ٓ��e
    XxcsoLookupListVOImpl spDecContentListVo
      = getXxcsoSpDecContentListVO();
    if ( spDecContentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecContentListVO");
    }

    spDecContentListVo.initQuery(
      "XXCSO1_SP_DECISION_CONTENT"
     ,"lookup_code"
    );

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �e�\�������̐ݒ菈��
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // �g�p����C���X�^���X���擾����    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }
    
    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    ///////////////////////////////////////////
    // �{����
    ///////////////////////////////////////////    
    XxcsoSpDecisionPropertyUtils.setAttributeProperty(
      initVo
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * �C�x���g�O����
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �g�p����C���X�^���X���擾����    
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.convValue(
      txn
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �S���[�W�����̒l����
   * @param submitFlag       ��o�p�t���O
   *****************************************************************************
   */
  private void validateAll(
    boolean                              submitFlag
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    
    // �C���X�^���X�擾
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecisionBmFormatVOImpl bmFmtVo
      = getXxcsoSpDecisionBmFormatVO1();
    if ( bmFmtVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBmFormatVO1"
        );
    }

    // 2009-08-24 [��Q0001104] Add Start
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    // 2009-08-24 [��Q0001104] Add End


    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    // 2009-08-24 [��Q0001104] Add Start
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
    // 2009-08-24 [��Q0001104] Add End


    /////////////////////////////////////
    // �T�Z�N�ԑ��v�̌v�Z
    /////////////////////////////////////
    if ( submitFlag )
    {
      handleCalcProfitButton();
    }
    
    /////////////////////////////////////
    // �S���[�W�����̒l���f
    /////////////////////////////////////
    XxcsoSpDecisionReflectUtils.reflectAll(
      headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,bmFmtVo
    );
    
    /////////////////////////////////////
    // ���؏����F�ݒu��
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateInstallCust(
        txn
       ,headerVo
       ,installVo
       ,submitFlag
      )
    );
    /////////////////////////////////////
    // ���؏����F�_���
    /////////////////////////////////////
// 2009-04-14 [ST��QT1_0225] Mod Start
//    if ( ! "Y".equals(cntrctRow.getSameInstallAccountFlag()) )
//    {
//      errorList.addAll(
//        XxcsoSpDecisionValidateUtils.validateCntrctCust(
//          txn
//         ,headerVo
//         ,cntrctVo
//         ,submitFlag
//        )
//      );
//    }
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateCntrctCust(
        txn
       ,headerVo
       ,cntrctVo
       ,submitFlag
      )
    );
// 2009-04-14 [ST��QT1_0225] Mod End
    /////////////////////////////////////
    // ���؏����FVD���
    /////////////////////////////////////
    // 2009-08-24 [��Q0001104] Add Start
    // �\���敪���u�V�K�v�̏ꍇ�A�K�{�`�F�b�N�B�܂��́u�����˗��v�{�^���̏ꍇ
    if ((XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(headerRow.getApplicationType()) ||
        (XxcsoSpDecisionConstants.OPERATION_REQUEST.equals(requestRow.getOperationMode()))
       ))
    {
    // 2009-08-24 [��Q0001104] Add End
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.validateVdInfo(
          txn
         ,headerVo
         ,submitFlag
        )
      );
    // 2009-08-24 [��Q0001104] Add Start
    }
    // 2009-08-24 [��Q0001104] Add End
    /////////////////////////////////////
    // ���؏����F�������
    /////////////////////////////////////
    String condBizType = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();
    boolean bm1CheckFlag = false;
    boolean bm2CheckFlag = false;
    boolean bm3CheckFlag = false;
    boolean contributeFlag = false;

    // �����ʏ����̃`�F�b�N
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)             ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      XxcsoSpDecisionValidateUtils.validateScLine(
        txn
       ,headerVo
       ,scVo
       ,submitFlag
      );
      
      if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
      {
        contributeFlag = true;
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
      while ( scRow != null )
      {
        String bm1BmRate = scRow.getBm1BmRate();
        String bm2BmRate = scRow.getBm2BmRate();
        String bm3BmRate = scRow.getBm3BmRate();
        String bm1BmAmt  = scRow.getBm1BmAmount();
        String bm2BmAmt  = scRow.getBm2BmAmount();
        String bm3BmAmt  = scRow.getBm3BmAmount();
// �ۑ�ꗗNo.73�Ή� START
//        if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//        {
//          bm1CheckFlag = true;
//        }
//        if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//        {
//          bm1CheckFlag = true;
//        }
//        if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//        {
//          bm2CheckFlag = true;
//        }
//        if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//        {
//          bm2CheckFlag = true;
//        }
//        if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//        {
//          bm3CheckFlag = true;
//        }
//        if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//        {
//          bm3CheckFlag = true;
//        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
                txn
               ,bm1BmRate
               ,bm1BmAmt
             )
           )
        {
          bm1CheckFlag = true;
        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
               txn
              ,bm2BmRate
              ,bm2BmAmt
             )
           )
        {
          bm2CheckFlag = true;
        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
               txn
              ,bm3BmRate
              ,bm3BmAmt
             )
           )
        {
          bm3CheckFlag = true;
        }
// �ۑ�ꗗNo.73�Ή� END
        
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }

      scVo.first();
    }

    // �ꗥ�����E�e��ʏ����̃`�F�b�N
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)             ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
      {
        contributeFlag = true;
      }
      
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        XxcsoSpDecisionValidateUtils.validateAllCcLine(
          txn
         ,headerVo
         ,allCcVo
         ,submitFlag
        );
      
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
        while ( allCcRow != null )
        {
          String bm1BmRate = allCcRow.getBm1BmRate();
          String bm2BmRate = allCcRow.getBm2BmRate();
          String bm3BmRate = allCcRow.getBm3BmRate();
          String bm1BmAmt  = allCcRow.getBm1BmAmount();
          String bm2BmAmt  = allCcRow.getBm2BmAmount();
          String bm3BmAmt  = allCcRow.getBm3BmAmount();
// �ۑ�ꗗNo.73�Ή� START
//          if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//          {
//            bm3CheckFlag = true;
//          }
//          if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//          {
//            bm3CheckFlag = true;
//          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm1BmRate
                ,bm1BmAmt
               )
             )
          {
            bm1CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm2BmRate
                ,bm2BmAmt
               )
             )
          {
            bm2CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm3BmRate
                ,bm3BmAmt
               )
             )
          {
            bm3CheckFlag = true;
          }
// �ۑ�ꗗNo.73�Ή� END
          
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
        }

        allCcVo.first();
      }
      else
      {
        XxcsoSpDecisionValidateUtils.validateSelCcLine(
          txn
         ,headerVo
         ,selCcVo
         ,submitFlag
        );
        
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
        while ( selCcRow != null )
        {
          String bm1BmRate = selCcRow.getBm1BmRate();
          String bm2BmRate = selCcRow.getBm2BmRate();
          String bm3BmRate = selCcRow.getBm3BmRate();
          String bm1BmAmt  = selCcRow.getBm1BmAmount();
          String bm2BmAmt  = selCcRow.getBm2BmAmount();
          String bm3BmAmt  = selCcRow.getBm3BmAmount();
// �ۑ�ꗗNo.73�Ή� START
//          if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//          {
//            bm3CheckFlag = true;
//          }
//          if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//          {
//            bm3CheckFlag = true;
//          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm1BmRate
                ,bm1BmAmt
               )
             )
          {
            bm1CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm2BmRate
                ,bm2BmAmt
               )
             )
          {
            bm2CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm3BmRate
                ,bm3BmAmt
               )
             )
          {
            bm3CheckFlag = true;
          }
// �ۑ�ꗗNo.73�Ή� END
          
          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
        }

        selCcVo.first();
      }
    }
    
    /////////////////////////////////////
    // ���؏����F���̑�����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateOtherCondition(
        txn
       ,headerVo
       ,submitFlag
      )
    );

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateConditionReason(
        txn
       ,headerVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // ���؏����FBM1
    /////////////////////////////////////
    String bizCondType = installRow.getBusinessConditionType();
    String elecType = headerRow.getElectricityType();
    String bm1PaymentType = bm1Row.getBmPaymentType();
    Number bm1CustomerId = bm1Row.getCustomerId();
    String bm1VendorName = bm1Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType) ||
             bm1CheckFlag
           )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm1Cust(
              txn
             ,bm1Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm1CustomerId, bm1VendorName) )
          //{
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm1VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm1PaymentType
                 )
             )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm1Cust(
            txn
           ,bm1Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // ���؏����FBM2
    /////////////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    Number bm2CustomerId = bm2Row.getCustomerId();
    String bm2VendorName = bm2Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( bm2CheckFlag )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm2Cust(
              txn
             ,headerVo
             ,bm2Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm2CustomerId, bm2VendorName) )
          //{
          //  String regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
          //  if ( contributeFlag )
          //  {
          //    regionName
          //      = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
          //  }
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,regionName
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm2VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm2PaymentType
                 )
             )
          {
            String regionName
              = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
            if ( contributeFlag )
            {
              regionName
                = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
            }
            
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,regionName
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm2Cust(
            txn
           ,headerVo
           ,bm2Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // ���؏����FBM3
    /////////////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    Number bm3CustomerId = bm3Row.getCustomerId();
    String bm3VendorName = bm3Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( bm3CheckFlag )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm3Cust(
              txn
             ,bm3Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm3CustomerId, bm3VendorName) )
          //{
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm3VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm3PaymentType
                 )
             )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm3Cust(
            txn
           ,bm3Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // ���؏����FBM1/BM2/BM3�̑��t��R�[�h�̑��݃`�F�b�N
    /////////////////////////////////////
    boolean vendorIdDuplicateFlag = false;
    if ( bm1CustomerId != null )
    {
      if ( bm2CustomerId != null )
      {
        if ( bm1CustomerId.compareTo(bm2CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
      if ( bm3CustomerId != null )
      {
        if ( bm1CustomerId.compareTo(bm3CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
    }

    if ( bm2CustomerId != null )
    {
      if ( bm3CustomerId != null )
      {
        if ( bm2CustomerId.compareTo(bm3CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
    }

    if ( vendorIdDuplicateFlag )
    {
      if ( contributeFlag )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00526)
        );
      }
      else
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00521)
        );
      }
    }
    // 2009-10-14 [IE554,IE573] Add Start
    ///////////////////////////////////////
    //// ���؏����FBM1/BM2/BM3�̑��t�於�̑��݃`�F�b�N
    ///////////////////////////////////////
    //boolean vendorNameDuplicateFlag = false;
    //if ( bm1VendorName != null && ! "".equals(bm1VendorName) )
    //{
    //  if ( bm2VendorName != null && ! "".equals(bm2VendorName) )
    //  {
    //    if ( bm1VendorName.equals(bm2VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //  if ( bm3VendorName != null && ! "".equals(bm3VendorName) )
    //  {
    //    if ( bm1VendorName.equals(bm3VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //}
    //
    //if ( bm2VendorName != null && ! "".equals(bm2VendorName) )
    //{
    //  if ( bm3VendorName != null && ! "".equals(bm3VendorName) )
    //  {
    //    if ( bm2VendorName.equals(bm3VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //}
    //
    //if ( vendorNameDuplicateFlag )
    //{
    //  if ( contributeFlag )
    //  {
    //    errorList.add(
    //      XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00527)
    //    );
    //  }
    //  else
    //  {
    //    errorList.add(
    //      XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00522)
    //    );
    //  }
    //}
    // 2009-10-14 [IE554,IE573] Add End
    /////////////////////////////////////
    // ���؏����F�_�񏑂ւ̋L�ڎ���
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateContractContent(
        txn
       ,headerVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�T�Z�N�ԑ��v
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateEstimateProfit(
        txn
       ,headerVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�Y�t
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateAttach(
        txn
       ,attachVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�񑗐�
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateSend(
        txn
       ,headerVo
       ,scVo
       ,allCcVo
       ,selCcVo
       ,sendVo
       ,submitFlag
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �R�~�b�g�����ł��B
   *****************************************************************************
   */
  private boolean isSameVendorExist(
    Number vendorId
   ,String vendorName
  )
  {
    boolean returnValue = false;
    
    if ( vendorId == null        &&
         vendorName != null      &&
         ! "".equals(vendorName)
       )
    {
      XxcsoSpDecisionVendorCheckVOImpl checkVo
        = getXxcsoSpDecisionVendorCheckVO1();
      if ( checkVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoSpDecisionVendorCheckVO1"
          );
      }

      checkVo.initQuery(vendorName);

      if ( checkVo.first() != null )
      {
        returnValue = true;
      }
    }

    return returnValue;
  }


  
  /*****************************************************************************
   * �R�~�b�g�����ł��B
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N�����ł��B
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionRegistAMLocal");
  }



  /**
   * 
   * Container's getter for XxcsoInstallLocationListVO
   */
  public XxcsoLookupListVOImpl getXxcsoInstallLocationListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoInstallLocationListVO");
  }



  /**
   * 
   * Container's getter for XxcsoNewoldTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoNewoldTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoNewoldTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoMakerCodeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoMakerCodeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoMakerCodeListVO");
  }


  /**
   * 
   * Container's getter for XxcsoConditionBizTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoConditionBizTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoConditionBizTypeListVO");
  }



  /**
   * 
   * Container's getter for XxcsoFiexedPriceListVO
   */
  public XxcsoLookupListVOImpl getXxcsoFiexedPriceListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoFiexedPriceListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBm1SendTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoBm1SendTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBm1SendTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO2
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO2()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO3
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO3()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO3");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO2
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO2()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO3
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO3()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO3");
  }

  /**
   * 
   * Container's getter for XxcsoEmpAreaTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoEmpAreaTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoEmpAreaTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBusinessCondTypeListVO
   */
  public XxcsoBusinessCondTypeListVOImpl getXxcsoBusinessCondTypeListVO()
  {
    return (XxcsoBusinessCondTypeListVOImpl)findViewObject("XxcsoBusinessCondTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoExtRefOpclTypeListVO
   */
  public XxcsoExtRefOpclTypeListVOImpl getXxcsoExtRefOpclTypeListVO()
  {
    return (XxcsoExtRefOpclTypeListVOImpl)findViewObject("XxcsoExtRefOpclTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoStandardTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoStandardTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStandardTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricityTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricityTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricityTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoApplicationTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoApplicationTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoApplicationTypeListVO");
  }



  /**
   * 
   * Container's getter for XxcsoAllContainerTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoAllContainerTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAllContainerTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderFullVO1
   */
  public XxcsoSpDecisionHeaderFullVOImpl getXxcsoSpDecisionHeaderFullVO1()
  {
    return (XxcsoSpDecisionHeaderFullVOImpl)findViewObject("XxcsoSpDecisionHeaderFullVO1");
  }





















  /**
   * 
   * Container's getter for XxcsoSpDecisionInitVO1
   */
  public XxcsoSpDecisionInitVOImpl getXxcsoSpDecisionInitVO1()
  {
    return (XxcsoSpDecisionInitVOImpl)findViewObject("XxcsoSpDecisionInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionInstCustFullVO1
   */
  public XxcsoSpDecisionInstCustFullVOImpl getXxcsoSpDecisionInstCustFullVO1()
  {
    return (XxcsoSpDecisionInstCustFullVOImpl)findViewObject("XxcsoSpDecisionInstCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCntrctCustFullVO1
   */
  public XxcsoSpDecisionCntrctCustFullVOImpl getXxcsoSpDecisionCntrctCustFullVO1()
  {
    return (XxcsoSpDecisionCntrctCustFullVOImpl)findViewObject("XxcsoSpDecisionCntrctCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm1CustFullVO1
   */
  public XxcsoSpDecisionBm1CustFullVOImpl getXxcsoSpDecisionBm1CustFullVO1()
  {
    return (XxcsoSpDecisionBm1CustFullVOImpl)findViewObject("XxcsoSpDecisionBm1CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm2CustFullVO1
   */
  public XxcsoSpDecisionBm2CustFullVOImpl getXxcsoSpDecisionBm2CustFullVO1()
  {
    return (XxcsoSpDecisionBm2CustFullVOImpl)findViewObject("XxcsoSpDecisionBm2CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm3CustFullVO1
   */
  public XxcsoSpDecisionBm3CustFullVOImpl getXxcsoSpDecisionBm3CustFullVO1()
  {
    return (XxcsoSpDecisionBm3CustFullVOImpl)findViewObject("XxcsoSpDecisionBm3CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionScLineFullVO1
   */
  public XxcsoSpDecisionScLineFullVOImpl getXxcsoSpDecisionScLineFullVO1()
  {
    return (XxcsoSpDecisionScLineFullVOImpl)findViewObject("XxcsoSpDecisionScLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAllCcLineFullVO1
   */
  public XxcsoSpDecisionAllCcLineFullVOImpl getXxcsoSpDecisionAllCcLineFullVO1()
  {
    return (XxcsoSpDecisionAllCcLineFullVOImpl)findViewObject("XxcsoSpDecisionAllCcLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSelCcLineFullVO1
   */
  public XxcsoSpDecisionSelCcLineFullVOImpl getXxcsoSpDecisionSelCcLineFullVO1()
  {
    return (XxcsoSpDecisionSelCcLineFullVOImpl)findViewObject("XxcsoSpDecisionSelCcLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAttachFullVO1
   */
  public XxcsoSpDecisionAttachFullVOImpl getXxcsoSpDecisionAttachFullVO1()
  {
    return (XxcsoSpDecisionAttachFullVOImpl)findViewObject("XxcsoSpDecisionAttachFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendFullVO1
   */
  public XxcsoSpDecisionSendFullVOImpl getXxcsoSpDecisionSendFullVO1()
  {
    return (XxcsoSpDecisionSendFullVOImpl)findViewObject("XxcsoSpDecisionSendFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderInstCustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderInstCustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderInstCustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderCntrctCustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderCntrctCustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderCntrctCustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm1CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm1CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm1CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm2CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm2CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm2CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm3CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm3CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm3CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderScLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderScLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderScLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAllCcLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAllCcLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAllCcLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSelCcLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSelCcLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSelCcLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAttachVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAttachVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAttachVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSendVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSendVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSendVL1");
  }

  /**
   * 
   * Container's getter for XxcsoStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecContentListVO
   */
  public XxcsoLookupListVOImpl getXxcsoSpDecContentListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSpDecContentListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBusinessTypeListVO1
   */
  public XxcsoBusinessTypeListVOImpl getXxcsoBusinessTypeListVO1()
  {
    return (XxcsoBusinessTypeListVOImpl)findViewObject("XxcsoBusinessTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendInitVO1
   */
  public XxcsoSpDecisionSendInitVOImpl getXxcsoSpDecisionSendInitVO1()
  {
    return (XxcsoSpDecisionSendInitVOImpl)findViewObject("XxcsoSpDecisionSendInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoRuleBottleTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoRuleBottleTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoRuleBottleTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCcLineInitVO1
   */
  public XxcsoSpDecisionCcLineInitVOImpl getXxcsoSpDecisionCcLineInitVO1()
  {
    return (XxcsoSpDecisionCcLineInitVOImpl)findViewObject("XxcsoSpDecisionCcLineInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecRequestFullVO1
   */
  public XxcsoSpDecRequestFullVOImpl getXxcsoSpDecRequestFullVO1()
  {
    return (XxcsoSpDecRequestFullVOImpl)findViewObject("XxcsoSpDecRequestFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionVendorCheckVO1
   */
  public XxcsoSpDecisionVendorCheckVOImpl getXxcsoSpDecisionVendorCheckVO1()
  {
    return (XxcsoSpDecisionVendorCheckVOImpl)findViewObject("XxcsoSpDecisionVendorCheckVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderFullVO2
   */
  public XxcsoSpDecisionHeaderFullVOImpl getXxcsoSpDecisionHeaderFullVO2()
  {
    return (XxcsoSpDecisionHeaderFullVOImpl)findViewObject("XxcsoSpDecisionHeaderFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionInstCustFullVO2
   */
  public XxcsoSpDecisionInstCustFullVOImpl getXxcsoSpDecisionInstCustFullVO2()
  {
    return (XxcsoSpDecisionInstCustFullVOImpl)findViewObject("XxcsoSpDecisionInstCustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCntrctCustFullVO2
   */
  public XxcsoSpDecisionCntrctCustFullVOImpl getXxcsoSpDecisionCntrctCustFullVO2()
  {
    return (XxcsoSpDecisionCntrctCustFullVOImpl)findViewObject("XxcsoSpDecisionCntrctCustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm1CustFullVO2
   */
  public XxcsoSpDecisionBm1CustFullVOImpl getXxcsoSpDecisionBm1CustFullVO2()
  {
    return (XxcsoSpDecisionBm1CustFullVOImpl)findViewObject("XxcsoSpDecisionBm1CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm2CustFullVO2
   */
  public XxcsoSpDecisionBm2CustFullVOImpl getXxcsoSpDecisionBm2CustFullVO2()
  {
    return (XxcsoSpDecisionBm2CustFullVOImpl)findViewObject("XxcsoSpDecisionBm2CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm3CustFullVO2
   */
  public XxcsoSpDecisionBm3CustFullVOImpl getXxcsoSpDecisionBm3CustFullVO2()
  {
    return (XxcsoSpDecisionBm3CustFullVOImpl)findViewObject("XxcsoSpDecisionBm3CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionScLineFullVO2
   */
  public XxcsoSpDecisionScLineFullVOImpl getXxcsoSpDecisionScLineFullVO2()
  {
    return (XxcsoSpDecisionScLineFullVOImpl)findViewObject("XxcsoSpDecisionScLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAllCcLineFullVO2
   */
  public XxcsoSpDecisionAllCcLineFullVOImpl getXxcsoSpDecisionAllCcLineFullVO2()
  {
    return (XxcsoSpDecisionAllCcLineFullVOImpl)findViewObject("XxcsoSpDecisionAllCcLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSelCcLineFullVO2
   */
  public XxcsoSpDecisionSelCcLineFullVOImpl getXxcsoSpDecisionSelCcLineFullVO2()
  {
    return (XxcsoSpDecisionSelCcLineFullVOImpl)findViewObject("XxcsoSpDecisionSelCcLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAttachFullVO2
   */
  public XxcsoSpDecisionAttachFullVOImpl getXxcsoSpDecisionAttachFullVO2()
  {
    return (XxcsoSpDecisionAttachFullVOImpl)findViewObject("XxcsoSpDecisionAttachFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendFullVO2
   */
  public XxcsoSpDecisionSendFullVOImpl getXxcsoSpDecisionSendFullVO2()
  {
    return (XxcsoSpDecisionSendFullVOImpl)findViewObject("XxcsoSpDecisionSendFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderInstCustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderInstCustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderInstCustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderCntrctCustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderCntrctCustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderCntrctCustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm1CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm1CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm1CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm2CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm2CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm2CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm3CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm3CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm3CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderScLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderScLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderScLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAllCcLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAllCcLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAllCcLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSelCcLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSelCcLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSelCcLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAttachVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAttachVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAttachVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSendVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSendVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSendVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBmFormatVO1
   */
  public XxcsoSpDecisionBmFormatVOImpl getXxcsoSpDecisionBmFormatVO1()
  {
    return (XxcsoSpDecisionBmFormatVOImpl)findViewObject("XxcsoSpDecisionBmFormatVO1");
  }






}