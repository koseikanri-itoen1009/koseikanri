/*============================================================================
* �t�@�C���� : XxcsoSpDecisionNotificationAMImpl
* �T�v����   : SP�ꌈ�ʒm��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * SP�ꌈ���̏��F�˗��^�m�F�˗��^�ی��ʒm�^�ԋp�ʒm�^���F�����ʒm���s�����߂�
 * �A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionNotificationAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionNotificationAMImpl()
  {
  }

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @param notifyId �ʒmID
   *****************************************************************************
   */
  public void initDetails(
    String notifyId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionNotificationVOImpl ntfVo
      = getXxcsoSpDecisionNotificationVO1();
    if ( ntfVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionNotificationVOImpl"
        );
    }

    ntfVo.initQuery(notifyId);
    
    XxcsoUtils.debug(txn, "[END]");
  }
  
  /**
   * 
   * Container's getter for XxcsoSpDecisionNotificationVO1
   */
  public XxcsoSpDecisionNotificationVOImpl getXxcsoSpDecisionNotificationVO1()
  {
    return (XxcsoSpDecisionNotificationVOImpl)findViewObject("XxcsoSpDecisionNotificationVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionNotificationAMLocal");
  }


}