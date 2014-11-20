/*============================================================================
* �t�@�C���� : XxcsoSalesPlanOutCO
* �T�v����   : ����v��o�̓R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-12 1.0  SCS�ێR����  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.webui;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/*******************************************************************************
 * ����v��o�͉�ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�ێR����
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanOutCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");


  /*****************************************************************************
   * ��ʋN�����̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    super.processRequest(pageContext, webBean);

    // �����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }
    // �����\���������s
    am.invokeMethod("initDetails");

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g�̏������s���܂��B
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
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u�߂�v�{�^��
    if ( pageContext.getParameter("BackButton") != null )
    {
      // ���j���[��ʂ֑J��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,null
        ,true
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // �u�i�ށv�{�^��
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {

      am.invokeMethod("handleCsvCreateButton");

      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }
}
