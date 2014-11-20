/*============================================================================
* �t�@�C���� : XxpoInspectLotSearchCO
* �T�v����   : �������b�g��񌟍��R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c ���    �V�K�쐬
* 2008-05-09 1.1  �F�{ �a�Y      �����ύX�v��#28,41,43�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Map;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

/***************************************************************************
 * �������b�g:�����R���g���[���N���X�ł��B
 * @author  ORACLE �˒J�c ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotSearchCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchCO.java,v 1.5 2008/02/22 06:25:20 usr3149 Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false))
    {
      // �g�����U�N�V�����J�n
      TransactionUnitHelper.startTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // ����������
      am.invokeMethod("initialize");
      // ���[�U�[���擾 
      Map retHashMap = new HashMap();
      retHashMap = (Map)am.invokeMethod("getUserData");

      // �]�ƈ��敪��"2":�O�����[�U�̏ꍇ
      String peopleCode = (String)retHashMap.get("PeopleCode");

      // ��ʐ���̂��߂Ɏ擾
      OAMessageLovInputBean searchVendorCode =
        (OAMessageLovInputBean)webBean.findChildRecursive(
          "SearchVendorNo");

      if ("2".equals(peopleCode))
      {   
        //���ځu�����v����͕s�ɐݒ�
        searchVendorCode.setReadOnly(true);
        searchVendorCode.setCSSClass("OraDataText");
      }
    } else
    {
      // �g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(
            pageContext, XxpoConstants.TXN_XXPO370001J, true))
      {
        pageContext.redirectToDialogPage(new OADialogPage(NAVIGATION_ERROR));
      }
    }
  }
    
  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // �ϐ���`
    String vendorCode = null;         // �����
    String vendorName = null;         // ����於
    String itemCode = null;           // �i��
    String itemName = null;           // �i�ږ�
    String itemId = null;             // �i��ID
    String lotNo = null;              // ���b�g�ԍ�
    String productFactory = null;     // �����H��
    String productLotNo = null;       // �������b�g�ԍ�
    String productDateFrom = null;    // ������/�d����(��)
    String productDateTo = null;      // ������/�d����(��)
    String creationDateFrom = null;   // ���͓�(��)
    String creationDateTo = null;     // ���͓�(��)
    String qtInspectReqNo = null;     // �����˗�No

    String apiName = "ProcessFormRequest";

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
// del start 1.1
//    // ��ʐ���̂��߂Ɏ擾
//    OAMessageStyledTextBean prompt =
//      (OAMessageStyledTextBean)webBean.findChildRecursive("PromptVendor");
// del end 1.1
    // =============================== //
    // =   �i�ރ{�^�����������ꂽ�ꍇ   = //
    // =============================== //
    if (pageContext.getParameter("Go") != null)
    {
      // �K�{���ڃ`�F�b�N
      am.invokeMethod("searchInputCheck");
      // ********************* //
      // *      �������s      * //
      // ********************* //
      try
      {
        am.invokeMethod("doSearch");
      } catch (OAException expt) 
      {
        // DB�G���[�����������ꍇ�́A�G���[��ʂɑJ�ڂ���B
        OADialogPage dialogPage =
          new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);      
      }

      // �g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

    // =============================== //
    // =   �����{�^�����������ꂽ�ꍇ   = //
    // =============================== //
    } else if (pageContext.getParameter("Clear") != null)
    {
      // �g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // ����ʂɑJ��(������ʂ̍ĕ\��)
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchPG",
        XxpoConstants.URL_XXPO370001J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        false,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // =============================== //
    // =   �V�K�{�^�����������ꂽ�ꍇ   = //
    // =============================== //
    } else if (pageContext.getParameter("New") != null)
    {
      // �g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // ************************* //
      // * �������b�g���o�^��ʂ� * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
        XxpoConstants.URL_XXPO370002J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        false, //retainAM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // =============================== //
    // =  ���b�g�ԍ����N���b�N�����ꍇ   = //
    // =============================== //
    } else if ("LotNoClick".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      // �g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // ************************* //
      // * �������b�g���o�^��ʂ� * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
        XxpoConstants.URL_XXPO370002J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true, //retainAM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);
        
    }
  }
}
