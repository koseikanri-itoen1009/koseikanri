/*============================================================================
* �t�@�C���� : XxcsoDeptMonthlyPlansRegistCO
* �T�v����   : ����v��̑I����͉�ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OADialogPage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso019003j.util.XxcsoDeptMonthlyPlansConstants;
/*******************************************************************************
 * ����v��̑I����͉�ʂ̃R���g���[���N���X
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansRegistCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN��������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    boolean errorMode = false;
    super.processRequest(pageContext, webBean);

    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    // �������ɐݒ肵�����\�b�h���̃��\�b�h��Call���܂��B
    Boolean returnValue = Boolean.TRUE;

    am.invokeMethod("initDetails");

    // �|�b�v���X�g������
    am.invokeMethod("initPoplist");

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g����������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    super.processFormRequest(pageContext, webBean);

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u����v�{�^��
    if ( pageContext.getParameter("CancelButton") != null )
    {
      // ���j���[��ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�K�p�v�{�^��
    if ( pageContext.getParameter("ApplicableButton") != null )
    {
      HashMap returnValue
        = (HashMap)am.invokeMethod("handleApplicableButton");
      OAException msg
        = (OAException)returnValue.get(
          XxcsoDeptMonthlyPlansConstants.RETURN_PARAM_MSG);

      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_DEPT_MONTHLY_PLANS_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
  }

}
