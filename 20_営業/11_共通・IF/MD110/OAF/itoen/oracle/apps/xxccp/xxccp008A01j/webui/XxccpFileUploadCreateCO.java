/*============================================================================
* �t�@�C���� : XxccpFileUploadCreateCO
* �T�v����   : CSV�t�@�C���A�b�v���[�h�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp008A01j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxccp.util.XxccpConstants;
import itoen.oracle.apps.xxccp.util.webui.XxccpOAControllerImpl;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

import oracle.cabo.ui.data.DataObject;


/**
 * �t�@�C���A�b�v���[�h�R���g���[���B
 * @author  SCS KUME
 * @version 1.0
 */
public class XxccpFileUploadCreateCO extends XxccpOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxccp/xxccp008A01j/webui/XxccpFileUploadCreateCO.java,v 1.3 2008/02/21 04:51:01 usr3149 Exp $";
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
    // �u���E�U�u�߂�v�{�^���̑Ή�
    if (!pageContext.isBackNavigationFired(false))
    {
      TransactionUnitHelper.startTransactionUnit(pageContext, 
                                                XxccpConstants.TXN_XXCCP008A01J);
      // �p�����[�^�擾(�t�@�C���A�b�v���[�h�R�[�h)
      String contentType = pageContext.getParameter(XxccpConstants.XXCCP008A01J_PARAM);

      if (contentType == null)
      {
        // �V�X�e���G���[
        // �ݒ�̕s���ɂ���Ĕ�������G���[�B�G���[��ʂɑJ�ڂ�����B
        TransactionUnitHelper.endTransactionUnit(pageContext, XxccpConstants.TXN_XXCCP008A01J);
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // �A�v���P�[�V�������W���[���̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      String meaning = null;
      try {
        // �Q�ƃ^�C�v���R���J�����g���̂���уt�H�[�}�b�g�p�^�[�����擾����B
        Serializable[] params = {XxccpConstants.LOOKUP_TYPE, contentType};
        meaning = (String)am.invokeMethod("getLookUpValue", params);
        // �i�[�p���R�[�h�쐬
        am.invokeMethod("createXxccpMrpFileUlInterfaceRec");
      } catch (OAException ex) 
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, XxccpConstants.TXN_XXCCP008A01J);
        // DB�G���[�����������ꍇ�́A�G���[��ʂɑJ�ڂ���B
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // �w�b�_�[���ڃ^�C�g��
      OAPageLayoutBean plRN = (OAPageLayoutBean)webBean;
      // Window Title����уy�[�W���̂̐ݒ�B
      StringBuffer dispBuf = new StringBuffer();
      dispBuf.append(XxccpConstants.DISP_TEXT);
      dispBuf.append(meaning);
      plRN.setTitle(dispBuf.toString());
      plRN.setWindowTitle(dispBuf.toString());

    } else
    {
      // �u���E�U�u�߂�v�{�^���ɑΉ�
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, 
                                                             XxccpConstants.TXN_XXCCP008A01J, 
                                                             true))
      {
        // �߂�{�^������������Ă���ꍇ�̏����B
        OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
    }
  } // end processRequest

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    // ApplicationModule�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    // �K�p�{�^���̔��f
    if (pageContext.getParameter("Apply") != null)
    {
      // �R���e���g�^�C�v�̎擾
      String contentType = pageContext.getParameter("LookupCode");
       // �R���J�����g�v���O�������̂̎擾
      String concurrentName = pageContext.getParameter("Description");
       // �v���O�������̎擾
      String programName = pageContext.getParameter("ProgramName");
      // �t�@�C�����̂̎擾
      String fileName = pageContext.getParameter("FileData");
      if (fileName == null || concurrentName == null || contentType == null)
      {
        // �t�@�C�������w�肳��Ă��Ȃ��B
        throw new OAException(XxccpConstants.APPL_XXCCP,
                              XxccpConstants.XXCCP191000,
                              null,
                              OAException.ERROR,
                              null);
      }
      // �t�@�C�����̎w��̗L�����`�F�b�N����B
      DataObject data = (DataObject)pageContext.getNamedDataObject("FileData");
      if (data == null)
      {
        // ���[���o�b�N����B
        am.invokeMethod("rollbackXxccpMrpFileUlInterface");
        throw new OAException(XxccpConstants.APPL_XXCCP,
                              XxccpConstants.XXCCP191000,
                              null,
                              OAException.ERROR,
                              null);
      }
      // �����ݒ�
      Serializable params[] = {fileName, contentType};
      // �����^�ݒ�
      Class[] parameterTypes = {String.class, String.class};
      // �߂�l��`
      long retVal = 0;
      try {
        // VO�ɐݒ�B
        am.invokeMethod("setUlFileInfo", params, parameterTypes);
        // �R�~�b�g�B
        am.invokeMethod("apply");
        // �R���J�����g���N������B
        params = new Serializable[] {concurrentName, contentType};
        Serializable[] returnObj = {am.invokeMethod("concRun", params)};
        retVal = ((Long)returnObj[0]).longValue();
      } catch (OAException ex) 
      {
        // ���[���o�b�N����B
        am.invokeMethod("rollbackXxccpMrpFileUlInterface");
        TransactionUnitHelper.endTransactionUnit(pageContext, XxccpConstants.TXN_XXCCP008A01J);
        // DB�G���[�����������ꍇ�́A�G���[��ʂɑJ�ڂ���B
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      if (retVal == 0)
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, 
          XxccpConstants.TXN_XXCCP008A01J);
        // �R���J�����g���N���ł��Ȃ��ꍇ�̏������L�q����B
        MessageToken[] tokens = { new MessageToken("PROGRAM", programName)};
        OAException ex1 = new OAException(XxccpConstants.APPL_XXCCP,
                                          XxccpConstants.XXCCP191001,
                                          tokens,
                                          OAException.ERROR,
                                          null);
        // �G���[���b�Z�[�W��ݒ肷��B
        pageContext.putDialogMessage(ex1);
        HashMap map = new HashMap();
        map.put(XxccpConstants.XXCCP008A01J_PARAM, contentType);
        // ����y�[�W�֑J�ڂ���B
        pageContext.forwardImmediately(
          APPLICATION_JSP + "?page=/itoen/oracle/apps/xxccp/xxccp008A01j/webui/XxccpFileUploadPG",
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          map,
          true, // retain AM 
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

      } else
      {
        // �R�~�b�g�B
        am.invokeMethod("apply");
      }
      TransactionUnitHelper.endTransactionUnit(pageContext, XxccpConstants.TXN_XXCCP008A01J);
      // �������b�Z�[�W�쐬
      MessageToken[] tokens = { new MessageToken("PROGRAM", programName),
                                new MessageToken("ID",      String.valueOf(retVal))};
      OAException confirmMess = new OAException(XxccpConstants.APPL_XXCCP,
                                                XxccpConstants.XXCCP191002,
                                                tokens,
                                                OAException.CONFIRMATION,
                                                null);
      pageContext.putDialogMessage(confirmMess);
      HashMap map = new HashMap();
      map.put(XxccpConstants.XXCCP008A01J_PARAM, contentType);
      // ����y�[�W�ɑJ�ڂ���B
      pageContext.forwardImmediately(
        APPLICATION_JSP + "?page=/itoen/oracle/apps/xxccp/xxccp008A01j/webui/XxccpFileUploadPG",
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        map,
        true, // retain AM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    } else if (pageContext.getParameter("Cancel") != null)
    {
      TransactionUnitHelper.endTransactionUnit(pageContext,
                                               XxccpConstants.TXN_XXCCP008A01J);
      // ���[���o�b�N����B
      am.invokeMethod("rollbackXxccpMrpFileUlInterface");
      // �z�[���֑J�ڂ���B
      pageContext.forwardImmediately(XxccpConstants.URL_OAHOMEPAGE,
                                     GUESS_MENU_CONTEXT,
                                     null,
                                     null,
                                     false, // Do not retain AM
                                     ADD_BREAD_CRUMB_NO);
    }
  } // end processFormRequest
}
