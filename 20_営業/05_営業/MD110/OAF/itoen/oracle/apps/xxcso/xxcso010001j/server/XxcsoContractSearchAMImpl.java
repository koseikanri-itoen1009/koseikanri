/*============================================================================
* �t�@�C���� : XxcsoContractSearchAMImpl
* �T�v����   : �_�񏑌����A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS�y���    �V�K�쐬
* 2009-05-26 1.1  SCS�������l  [ST��QT1_1165]���׃`�F�b�N��Q�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso010001j.util.XxcsoContractConstants;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import oracle.jdbc.OracleCallableStatement;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.SQLException;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
// 2009-05-26 [ST��QT1_1165] Add Start
import oracle.jbo.domain.Number;
// 2009-05-26 [ST��QT1_1165] Add End

/*******************************************************************************
 * �_�񏑂��������邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoContractSearchAMImpl extends OAApplicationModuleImpl 
{

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSearchAMImpl()
  {
  }

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @throw OAException
   *****************************************************************************
   */
  public void initDetails()
  {
    //SP�ꌈ���ԍ��I������������
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }
    // ����ʂ���̑J�ڍl��
    if ( ! newVo.isPreparedForExecution() )
    {
      // �������������s
      newVo.executeQuery();
    }

    // ��������������
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoContractQueryTermsVOImpl");
    }
    // ����ʂ���̑J�ڍl��
    if ( ! termsVo.isPreparedForExecution() )
    {
      // �������������s
      termsVo.executeQuery();

      // ���׏�����
      XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
      if ( summaryVo == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
      }

      // ���ׂ̃{�^�����\���ɐݒ�
      ControlBtn( XxcsoContractConstants.CONSTANT_COM_KBN2 );
    }
  }

  /*****************************************************************************
   * �Q��SP�ꌈ���ԍ����ڃG���[�`�F�b�N�����ł��B
   * @return returnValue
   * @throw  OAException
   *****************************************************************************
   */
  public Boolean spHeaderCheck()
  {
    Boolean returnValue = Boolean.TRUE;

    // XxcsoContractNewVO1�C���X�^���X�̎擾
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }

    XxcsoContractNewVORowImpl newRow = (XxcsoContractNewVORowImpl)newVo.first();
    if ( newRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVORowImpl");
    }

    //�����̓`�F�b�N
    if ( newRow.getSpDecisionNumber() == null )
    {
      mMessage
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005,
            XxcsoConstants.TOKEN_COLUMN,
            XxcsoContractConstants.MSG_SP_DECISION_NUMBER
          );
      returnValue = Boolean.FALSE;
    }
    else
    {
      // XxcsoContractAuthorityCheckVO1�C���X�^���X�̎擾
      XxcsoContractAuthorityCheckVOImpl checkVo
        = getXxcsoContractAuthorityCheckVO1();
      if ( checkVo == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractAuthorityCheckVOImpl");
      }
      //�����`�F�b�N�p�b�P�[�WCALL
      checkVo.getAuthority(newRow.getSpDecisionHeaderId());

      XxcsoContractAuthorityCheckVORowImpl checkRow
        = (XxcsoContractAuthorityCheckVORowImpl)checkVo.first();

      if ( checkRow == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractAuthorityCheckVORowImpl");
      }
      // �����G���[
      if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
             checkRow.getAuthority()) )
      {
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00232,
              XxcsoConstants.TOKEN_REF_OBJECT,
              XxcsoContractConstants.MSG_SP_DECISION,
              XxcsoConstants.TOKEN_CRE_OBJECT,
              XxcsoContractConstants.MSG_CONTRACT
            );
        returnValue = Boolean.FALSE;
      }
    }
    return returnValue;
  }

  /*****************************************************************************
   * �i�ރ{�^�������������ۂ̏����ł��B
   * @return returnValue
   * @throw  OAException
   *****************************************************************************
   */
  public void executeSearch()
  {
    // ���������擾
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoContractQueryTermsVOImpl");
    }

    XxcsoContractQueryTermsVORowImpl termsRow
      = (XxcsoContractQueryTermsVORowImpl)termsVo.first();
    if ( termsRow == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoContractQueryTermsVORowImpl");
    }

    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    //�����������S�Đݒ肳��Ă��Ȃ��ꍇ�̓G���[
    if ( (termsRow.getContractNumber() == null ) &&
         (termsRow.getInstallAccountNumber() == null) &&
         (termsRow.getInstallpartyName() == null) )
    {
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00041);
    }
    else
    {
      // �������s
      summaryVo.initQuery(
        termsRow.getContractNumber(),
        termsRow.getInstallAccountNumber(),
        termsRow.getInstallpartyName()
      );

     // �����`�F�b�N(first��null�`�F�b�N)
     XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

     if ( summaryRow != null )
     {
      //�������ʂ�����ꍇ�̓{�^�����g�p�ɂ���
      ControlBtn( XxcsoContractConstants.CONSTANT_COM_KBN1 );
     }
     else
     {
      //����ȊO�̓{�^�����g�p�s�ɂ���
      ControlBtn( XxcsoContractConstants.CONSTANT_COM_KBN2 );
     }
    }
  }

  /*****************************************************************************
   * �����{�^�������������ۂ̏����ł��B
   * @throw OAException
   *****************************************************************************
   */
  public void ClearBtn()
  {
    // ��������������
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractQueryTermsVOImpl");
    }
    termsVo.executeQuery();
  }

  /*****************************************************************************
   * ���׃G���[�`�F�b�N�����ł��B
   * @param  mode
   * @return returnValue
   * @throw  OAException
   *****************************************************************************
   */
  public Boolean selCheck(String mode)
  {
// 2009-05-26 [ST��QT1_1165] Del Start
//    Boolean returnValue = Boolean.TRUE;
//
//    //�������ʂ���I������Ă��郌�R�[�h�𔻒肵�A�p�����[�^�Ƃ��ĕԂ�
//    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
//    if ( summaryVo == null )
//    {
//      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
//    }
//
//    XxcsoContractSummaryVORowImpl summaryRow
//      = (XxcsoContractSummaryVORowImpl)summaryVo.first();
//
//    if ( summaryRow == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
//    }
//
//    //���[�v�J�E���g�p
//    int i = 0;
//    //�����G���[�ԍ�
//    String errorno = null;
//
//    //���בI���`�F�b�N
//    while ( summaryRow != null )
//    {
//      if ( "Y".equals(summaryRow.getSelectFlag()) )
//      {
//        //�`�F�b�N�J�E���g
//        i = ++i;
//
//        // XxcsoContractAuthorityCheckVO1�C���X�^���X�̎擾
//        XxcsoContractAuthorityCheckVOImpl checkVo
//          = getXxcsoContractAuthorityCheckVO1();
//        if ( checkVo == null )
//        {
//          throw XxcsoMessage.createInstanceLostError
//            ("XxcsoContractAuthorityCheckVOImpl");
//        }
//
//        //�����`�F�b�N�p�b�P�[�WCALL
//        checkVo.getAuthority(
//          summaryRow.getSpDecisionHeaderId()
//        );
//
//        XxcsoContractAuthorityCheckVORowImpl checkRow
//          = (XxcsoContractAuthorityCheckVORowImpl)checkVo.first();
//
//        if ( checkRow == null )
//        {
//          throw XxcsoMessage.createInstanceLostError
//            ("XxcsoContractAuthorityCheckVORowImpl");
//        }
//        //�G���[�ƂȂ���SP�ꌈ�w�b�_ID��ޔ�
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
//               checkRow.getAuthority()) )
//        {
//          errorno = summaryRow.getSpDecisionHeaderNum();
//        }
//
//        // PDF�쐬���̃G���[�`�F�b�N
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
//        {
//          // �t�H�[�}�b�g�`�F�b�N
//          if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
//                 summaryRow.getContractFormat())
//             )
//          {
//            mMessage
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00448
//                );
//            returnValue = Boolean.FALSE;
//          }
//        }
//        // �R�s�[�쐬�{�^���̃}�X�^�A�g�`�F�b�N
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) &&
//             XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
//               summaryRow.getStatuscd()) &&
//             XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
//               summaryRow.getCooperateFlag())
//             )
//        {
//          mMessage
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00397
//              );
//          returnValue = Boolean.FALSE;
//        }
//      }
//      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
//    }
//
//    //mode���R�s�[�쐬:1,�ڍ�:2,PDF�쐬:3
//    // PDF�쐬�I���Ŗ��I���̏ꍇ
//    if ( ( i == 0 ) &&
//         ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) ) )
//    {
//      mMessage
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00039,
//            XxcsoConstants.TOKEN_PARAM2,
//            XxcsoContractConstants.MSG_CONTRACT
//          );
//      returnValue = Boolean.FALSE;
//    }
//    // ���I��or�����s�I���̏ꍇ
//    else if ( ( i == 0 ) || ( i > 1 ) )
//    {
//      // �R�s�[�쐬
//      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00037,
//              XxcsoConstants.TOKEN_BUTTON,
//              XxcsoContractConstants.MSG_COPY_CREATE
//            );
//        returnValue = Boolean.FALSE;
//      }
//      // �ڍ�
//      else if ( XxcsoContractConstants.CONSTANT_COM_KBN2.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00037,
//              XxcsoConstants.TOKEN_BUTTON,
//              XxcsoContractConstants.MSG_DETAILS
//            );
//        returnValue = Boolean.FALSE;
//      }
//    }
//
//    //�����G���[
//    if ( ( i == 1 ) && ( errorno != null  ) )
//    {
//      // �R�s�[�쐬
//      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00232,
//              XxcsoConstants.TOKEN_REF_OBJECT,
//              XxcsoContractConstants.MSG_SP_DECISION,
//              XxcsoConstants.TOKEN_CRE_OBJECT,
//              XxcsoContractConstants.MSG_CONTRACT
//            );
//        returnValue = Boolean.FALSE;
//      }
//      // PDF�쐬
//      else if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00232,
//              XxcsoConstants.TOKEN_REF_OBJECT,
//              XxcsoContractConstants.MSG_CONTRACT,
//              XxcsoConstants.TOKEN_CRE_OBJECT,
//              XxcsoContractConstants.MSG_PDF_CREATE
//            );
//        returnValue = Boolean.FALSE;
//      }
//    }
//
//    //�擪�s�ɃJ�[�\����߂�
//    summaryVo.first();
//
//    return returnValue;
// 2009-05-26 [ST��QT1_1165] Del End
// 2009-05-26 [ST��QT1_1165] Add Start
    // ���\�b�h�����e�����l
    final String CONTRACT_NUMBER       = "CONTRACT_NUBMER";
    final String CONTRACT_FORMAT       = "CONTRACT_FORMAT";
    final String SP_DECISION_HEADER_ID = "SP_DECISION_HEADER_ID";
    final String SP_DECISION_NUMBER    = "SP_DECISION_NUMBER";
    final String STATUS_CODE           = "STATUS_CODE";
    final String COOPERATE_FLAG        = "COOPERATE_FLAG";

    Boolean returnValue = Boolean.TRUE;

    XxcsoContractSummaryVOImpl sumVo = getXxcsoContractSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl sumRow
      = (XxcsoContractSummaryVORowImpl) sumVo.first();
    if ( sumRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }

    // �I���s��List���쐬
    List selList = new ArrayList();
    while ( sumRow != null )
    {
      if ( "Y".equals( sumRow.getSelectFlag() ) )
      {
        HashMap map = new HashMap(3);
        map.put( CONTRACT_NUMBER,       sumRow.getContractNumber()            );
        map.put( CONTRACT_FORMAT,       sumRow.getContractFormat()            );
        map.put( SP_DECISION_HEADER_ID, sumRow.getSpDecisionHeaderId()        );
        map.put( SP_DECISION_NUMBER,    sumRow.getSpDecisionHeaderNum()       );
        map.put( STATUS_CODE,           sumRow.getStatuscd()                  );
        map.put( COOPERATE_FLAG,        sumRow.getCooperateFlag()             );
        selList.add( map );
      }
      sumRow = (XxcsoContractSummaryVORowImpl) sumVo.next();
    }

    // �擪�s�ɃJ�[�\����߂�
    sumVo.first();

    ////////////////////
    // ���בI���`�F�b�N
    ////////////////////
    int listSize = selList.size();
    // ���בI����0��
    if ( listSize == 0
      && XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode)
    )
    {
      // PDF�쐬�{�^��
      mMessage
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00039
           ,XxcsoConstants.TOKEN_PARAM2
           ,XxcsoContractConstants.MSG_CONTRACT
          );
      returnValue = Boolean.FALSE;
    }
    // ���ׂ�0���A�܂��͕����I���̏ꍇ
    else if ( listSize == 0 || listSize > 1 )
    {
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      {
        // �R�s�[�쐬
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00037
             ,XxcsoConstants.TOKEN_BUTTON
             ,XxcsoContractConstants.MSG_COPY_CREATE
            );
        returnValue = Boolean.FALSE;
      }
      else if ( XxcsoContractConstants.CONSTANT_COM_KBN2.equals(mode) )
      {
        // �ڍ�
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00037
             ,XxcsoConstants.TOKEN_BUTTON
             ,XxcsoContractConstants.MSG_DETAILS
            );
        returnValue = Boolean.FALSE;
      }
    }

    // ���בI�𕔕��܂łň�U�G���[�������I��
    // ���ڍ׃{�^�������ɂ��Ă͕ʓr�}�X�^�A�g�`�F�b�N���s�����ߏI��
    if ( ! returnValue.booleanValue()
      ||   XxcsoContractConstants.CONSTANT_COM_KBN2.equals( mode )
    )
    {
      return returnValue;
    }

    ////////////////////
    // �}�X�^�A�g�`�F�b�N�A�t�H�[�}�b�g�`�F�b�N
    ////////////////////
    List authErrList = new ArrayList();

    for (int i = 0; i < listSize; i++ )
    {
      HashMap map = (HashMap) selList.get(i);
      String contractNumber     = (String) map.get( CONTRACT_NUMBER           );
      String contractFormat     = (String) map.get( CONTRACT_FORMAT           );
      Number spDecisionHeaderId = (Number) map.get( SP_DECISION_HEADER_ID     );
      String spDecisionNumber   = (String) map.get( SP_DECISION_NUMBER        );
      String statusCode         = (String) map.get( STATUS_CODE               );
      String cooperateFlag      = (String) map.get( COOPERATE_FLAG            );

      ////////////////////
      // �����`�F�b�N
      ////////////////////
      XxcsoContractAuthorityCheckVOImpl checkVo
        = getXxcsoContractAuthorityCheckVO1();
      if ( checkVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoContractAuthorityCheckVOImpl"
          );
      }

      //�����`�F�b�N�p�b�P�[�WCALL
      checkVo.getAuthority( spDecisionHeaderId );

      XxcsoContractAuthorityCheckVORowImpl checkRow
        = (XxcsoContractAuthorityCheckVORowImpl) checkVo.first();

      if ( checkRow == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractAuthorityCheckVORowImpl");
      }

      // �����G���[�`�F�b�N
      if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
            checkRow.getAuthority() ) )
      {
        //�G���[�ƂȂ����_�񏑔ԍ���ޔ�(List)
        authErrList.add( contractNumber );
      }

      ////////////////////
      // �_�񏑃t�H�[�}�b�g�`�F�b�N
      ////////////////////
      if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
      {
        // PDF�쐬�{�^���������̂݃t�H�[�}�b�g�`�F�b�N
        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals( contractFormat ) )
        {
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00448
              );
          returnValue = Boolean.FALSE;
        }
      }

      ////////////////////
      // �}�X�^�A�g�`�F�b�N
      ////////////////////
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      {
      // �R�s�[�{�^���������̂݃}�X�^�A�g�`�F�b�N
        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals( statusCode )
          && XxcsoContractConstants.CONSTANT_COM_KBN0.equals( cooperateFlag )
        )
        {
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00397
              );
          returnValue = Boolean.FALSE;
       }
      }
    }

    if ( ! returnValue.booleanValue() )
    {
      return returnValue;
    }

    ////////////////////
    // �����G���[�`�F�b�N
    ////////////////////
    if ( authErrList.size() > 0 )
    {
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      {
        // �R�s�[�쐬
        // �������I���͌����`�F�b�N�O�̏����ɂċN���肦�Ȃ�
        //   ��������ꍇ��1���I�����̂�
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00232,
              XxcsoConstants.TOKEN_REF_OBJECT,
              XxcsoContractConstants.MSG_SP_DECISION,
              XxcsoConstants.TOKEN_CRE_OBJECT,
              XxcsoContractConstants.MSG_CONTRACT
            );
        returnValue = Boolean.FALSE;
      }
      else if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
      {
        String tokenRecord = getContractNumMsg( authErrList );
        // PDF�쐬
        // �������I�����͔������ׂ̌_�񏑔ԍ������b�Z�[�W�ɕt��
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00571
             ,XxcsoConstants.TOKEN_REF_OBJECT
             ,XxcsoContractConstants.MSG_CONTRACT
             ,XxcsoConstants.TOKEN_CRE_OBJECT
             ,XxcsoContractConstants.MSG_PDF_CREATE
             ,XxcsoConstants.TOKEN_RECORD
             ,tokenRecord
            );
        returnValue = Boolean.FALSE;
      }
    }
    return returnValue;
// 2009-05-26 [ST��QT1_1165] Add End
  }

  /*****************************************************************************
   * �_�񏑍쐬�{�^�������������ۂ�URL�p�����[�^�擾�����ł��B
   * @throw  OAException
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamNew()
  {
    // ���������擾
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }
    
    XxcsoContractNewVORowImpl newRow
      = (XxcsoContractNewVORowImpl)newVo.first();
    if ( newRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVORowImpl");
    }

    HashMap params = new HashMap();
    // SP�ꌈ�w�b�_ID
    params.put(
      XxcsoConstants.TRANSACTION_KEY1,
      newRow.getSpDecisionHeaderId()
    );

    return params; 
  }

  /*****************************************************************************
   * �R�s�[�쐬�{�^�������������ۂ�URL�p�����[�^�擾�����ł��B
   * @throw  OAException
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamCopy()
  {
    //�������ʂ���I������Ă��郌�R�[�h�𔻒肵�A�p�����[�^�Ƃ��ĕԂ�
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    HashMap params = new HashMap();

    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // XxcsoContractAuthorityCheckVO1�C���X�^���X�̎擾
        XxcsoContractAuthorityCheckVOImpl checkVo
          = getXxcsoContractAuthorityCheckVO1();
        if ( checkVo == null )
        {
          throw XxcsoMessage.createInstanceLostError
            ("XxcsoContractAuthorityCheckVOImpl");
        }
        // �����敪
        params.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoContractConstants.CONSTANT_COM_KBN2
        );
        // SP�ꌈ�w�b�_ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY1,
          summaryRow.getSpDecisionHeaderId()
        );
        // �����̔��@�ݒu�_��ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY2,
          summaryRow.getContractManagementId()
        );
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }
    return params; 
  }

  /*****************************************************************************
   * �ڍ׃{�^�������������ۂ�URL�p�����[�^�擾�����ł��B
   * @throw  OAException
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamDetails()
  {
    //�������ʂ���I������Ă��郌�R�[�h�𔻒肵�A�p�����[�^�Ƃ��ĕԂ�
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    HashMap params = new HashMap();

    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // XxcsoContractAuthorityCheckVO1�C���X�^���X�̎擾
        XxcsoContractAuthorityCheckVOImpl checkVo
          = getXxcsoContractAuthorityCheckVO1();
        if ( checkVo == null )
        {
          throw XxcsoMessage.createInstanceLostError
            ("XxcsoContractAuthorityCheckVOImpl");
        }
        // �����敪
        params.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoContractConstants.CONSTANT_COM_KBN1
        );
        // SP�ꌈ�w�b�_ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY1,
          summaryRow.getSpDecisionHeaderId()
        );
        // �����̔��@�ݒu�_��ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY2,
          summaryRow.getContractManagementId()
        );
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }
    return params; 
  }

  /*****************************************************************************
   * �R�s�[�쐬�A�ڍׁAPDF�쐬�{�^���̐��䏈���ł��B
   * @throw OAException
   *****************************************************************************
   */
  public void ControlBtn(String contbtn)
  {
      XxcsoContractRenderVOImpl renderVo = getXxcsoContractRenderVO1();
      if ( renderVo == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractRenderVOImpl");
      }

      XxcsoContractRenderVORowImpl renderRow
        = (XxcsoContractRenderVORowImpl)renderVo.first();
      if ( renderRow == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractRenderVORowImpl");
      }
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(contbtn) )
      {
        renderRow.setContractRender(Boolean.TRUE); // �\��
      }
      else
      {
        renderRow.setContractRender(Boolean.FALSE); // ��\��
      }
  }

  /*****************************************************************************
   * �_�񏑈���{�^������������
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public void handlePdfCreateButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    NUMBER requestId = null;
    OracleCallableStatement stmt = null;

    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // ���Ϗ����PG��CALL
        requestId = null;
        stmt = null;

        try
        {
          StringBuffer sql = new StringBuffer(100);
          sql.append("BEGIN");
          sql.append("  :1 := fnd_request.submit_request(");
          sql.append("         application       => 'XXCSO'");
          sql.append("        ,program           => 'XXCSO010A04C'");
          sql.append("        ,description       => NULL");
          sql.append("        ,start_time        => NULL");
          sql.append("        ,sub_request       => FALSE");
          sql.append("        ,argument1         => :2");
          sql.append("       );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.NUMBER);
          stmt.setString(2, summaryRow.getContractManagementId().stringValue());

          stmt.execute();

          requestId = stmt.getNUMBER(1);
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
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
               ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
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
               ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
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
        // ����I�����b�Z�[�W
        OAException error
          = XxcsoMessage.createConfirmMessage(
              XxcsoConstants.APP_XXCSO1_00001
             ,XxcsoConstants.TOKEN_RECORD
             ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
                + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
                + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
                + requestId.stringValue()
                + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,XxcsoConstants.TOKEN_ACTION
             ,XxcsoContractConstants.TOKEN_VALUE_START
            );
        errorList.add(error);

      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    // �J�[�\����擪�ɂ���
    summaryVo.first();

    commit();

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * �}�X�^�A�g�`�F�b�N�����ł��B
   * @return returnValue
   * @throw  OAException
   *****************************************************************************
   */
  public Boolean handleCooperateChk()
  {
    Boolean returnValue = Boolean.TRUE;

    //�C���X�^���X�擾
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    if ( summaryRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }

    //���בI���`�F�b�N
    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // �}�X�^�A�g�`�F�b�N
        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
               summaryRow.getStatuscd()) &&
             XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
               summaryRow.getCooperateFlag())
           )
        {
          // �ڍׁAPDF�쐬�͊m�F�_�C�A���O��\��
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00398
              );
          returnValue = Boolean.FALSE;
        }
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    //�擪�s�ɃJ�[�\����߂�
    summaryVo.first();

    return returnValue;
  }

  /*****************************************************************************
   * �m�F�_�C�A���OOK�{�^�������������iPDF�j
   * �i�_�C�A���O���o�͎����o�^�����Ƃ���Call�����j
   *****************************************************************************
   */
  public void handleConfirmPdfOkButton()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    XxcsoUtils.debug(txn, "PDF�o�͏���");
    this.handlePdfCreateButton();

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * �R�~�b�g����
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

// 2009-05-26 [ST��QT1_1165] Add Start
  /*****************************************************************************
   * �G���[�Ώی_�񏑔ԍ��擾
   *****************************************************************************
   */
  private String getContractNumMsg(List list)
  {
    // �G���[���b�Z�[�W�t�����b�Z�[�W�̐����i�_�񏑔ԍ��j
    StringBuffer sbNumber = new StringBuffer();
    sbNumber.append( XxcsoContractConstants.MSG_CONTRACT_NUMBER );
    sbNumber.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );

    int listSize = list.size();
    for (int i = 0; i < listSize; i++)
    {
      String contractNumber = (String) list.get(i);
      if ( i != 0 )
      {
        sbNumber.append( XxcsoConstants.TOKEN_VALUE_DELIMITER2 );
      }
      sbNumber.append( contractNumber );
    }

    return new String( sbNumber );
  }
// 2009-05-26 [ST��QT1_1165] Add End

  /**
   * 
   * Container's getter for XxcsoContractQueryTermsVO1
   */
  public XxcsoContractQueryTermsVOImpl getXxcsoContractQueryTermsVO1()
  {
    return (XxcsoContractQueryTermsVOImpl)findViewObject("XxcsoContractQueryTermsVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractSummaryVO1
   */
  public XxcsoContractSummaryVOImpl getXxcsoContractSummaryVO1()
  {
    return (XxcsoContractSummaryVOImpl)findViewObject("XxcsoContractSummaryVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.server", "XxcsoContractSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoContractNewVO1
   */
  public XxcsoContractNewVOImpl getXxcsoContractNewVO1()
  {
    return (XxcsoContractNewVOImpl)findViewObject("XxcsoContractNewVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractAuthorityCheckVO1
   */
  public XxcsoContractAuthorityCheckVOImpl getXxcsoContractAuthorityCheckVO1()
  {
    return (XxcsoContractAuthorityCheckVOImpl)findViewObject("XxcsoContractAuthorityCheckVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractRenderVO1
   */
  public XxcsoContractRenderVOImpl getXxcsoContractRenderVO1()
  {
    return (XxcsoContractRenderVOImpl)findViewObject("XxcsoContractRenderVO1");
  }


}