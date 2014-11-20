/*============================================================================
* �t�@�C���� : XxcsoUtils
* �T�v����   : �y�A�h�I���F�c�ƁE�c�Ɨ̈�z���ʊ֐��N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-24 1.0  SCS�������l  �V�K�쐬
* 2008-12-07 1.0  SCS����_    �f�o�b�O�o�́i���[�J���p�j�ǉ�
* 2008-12-10 1.0  SCS����_    �ő匏���`�F�b�N�֐��ǉ�
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAFwkConstants;

/*******************************************************************************
 * �A�h�I���F���ʊ֐��N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUtils 
{
  /*****************************************************************************
   * �f�o�b�O���x��
   *****************************************************************************
   */
  private static final int DEBUG_LEVEL = OAFwkConstants.EXCEPTION;
  
  /*****************************************************************************
   * �y�[�W�ԃ��b�Z�[�W�ݒ�
   * @param pageContext       �y�[�W�R���e�L�X�g
   * @param OAException       ���b�Z�[�W
   *****************************************************************************
   */
  public static void setDialogMessage(
    OAPageContext pageContext
   ,OAException   message
  )
  {
    pageContext.putParameter("XXCSO_DURING_PAGE_MESSAGE", message);
  }

  /*****************************************************************************
   * �y�[�W�ԃ��b�Z�[�W�\��
   * @param pageContext       �y�[�W�R���e�L�X�g
   *****************************************************************************
   */
  public static void showDialogMessage(
    OAPageContext pageContext
  )
  {
    OAException message
      = (OAException)
          pageContext.getParameterObject("XXCSO_DURING_PAGE_MESSAGE");

    if ( message != null )
    {
      pageContext.putDialogMessage(message);
      pageContext.removeParameter("XXCSO_DURING_PAGE_MESSAGE");
    }
  }

  /*****************************************************************************
   * �ő匏���`�F�b�N
   * @param voRow             �r���[�s�C���X�^���X
   * @param objectName        �I�u�W�F�N�g��
   *****************************************************************************
   */
  public static void checkRowSize(
    OAViewRowImpl voRow
   ,String        objectName
  )
  {
    OAApplicationModule am = (OAApplicationModule)voRow.getApplicationModule();
    if ( am == null )
    {
      throw XxcsoMessage.createInstanceLostError("OAApplicationModule");
    }

    OADBTransaction txn = am.getOADBTransaction();
    String maxSize = txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    
    OAViewObjectImpl vo = (OAViewObjectImpl)voRow.getViewObject();
    if ( vo == null )
    {
      throw XxcsoMessage.createInstanceLostError("OAViewObjectImpl");
    }

    int lineCount = vo.getRowCount();

    if ( lineCount >= Integer.parseInt(maxSize) )
    {
      throw
        XxcsoMessage.createMaxRowException(
          objectName
         ,maxSize
        );
    }
  }

  /*****************************************************************************
   * �A�h�o���X�e�[�u�����[�W�����ւ̍ő�s�����̐ݒ�
   * @param pageContext       ��ʂ�OAPageContext
   * @param webBean           ��ʂ�OAWebBean
   * @param reginName         ���[�W������
   * @param profileOptionName �v���t�@�C���I�v�V������
   *****************************************************************************
   */
  public static OAException setAdvancedTableRows(
    OAPageContext pageContext
    ,OAWebBean    webBean
    ,String       reginName
    ,String       profileOptionName
    )
  {
    OAException oae = null;

    String lineNumStr = pageContext.getProfile(profileOptionName);
    if ( lineNumStr == null || "".equals(lineNumStr.trim()) )
    {
      oae = XxcsoMessage.createProfileNotFoundError(profileOptionName);
      return oae;
    }

    int lineNum = 0;
    try
    {
      lineNum = Integer.parseInt(lineNumStr);
    }
    catch ( NumberFormatException nfe )
    {
      oae =
        XxcsoMessage.createProfileOptionValueError(
          profileOptionName
          ,lineNumStr
        );
      return oae;
    }

    OAAdvancedTableBean advTbl
      = (OAAdvancedTableBean) webBean.findChildRecursive(reginName);
    advTbl.setNumberOfRowsDisplayed(lineNum);

    return oae;
  }

  /*****************************************************************************
   * �ُ�n���O��������
   * @param logger            OADBTransaction/OAPageContext�C���X�^���X
   * @param exception         Exception�C���X�^���X/String���b�Z�[�W
   *****************************************************************************
   */
  public static void unexpected(Object logger, Object exception)
  {
    Throwable t = new Throwable();
    StackTraceElement[] e = t.getStackTrace();

    StringBuffer sb = new StringBuffer();
    sb.append(e[2].toString());

    if ( logger instanceof OAPageContext )
    {
      ((OAPageContext)logger).writeDiagnostics(
        sb.toString()
       ,exception.toString()
       ,OAFwkConstants.UNEXPECTED
      );
    }

    if ( logger instanceof OADBTransaction )
    {
      ((OADBTransaction)logger).writeDiagnostics(
        sb.toString()
       ,exception.toString()
       ,OAFwkConstants.UNEXPECTED
      );
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iObject�^�j
   * @param context           OAPageContext�C���X�^���X
   * @param obj               �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OAPageContext context, Object  obj)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, obj);
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iObject�^�j
   * @param txn               OADBTransaction�C���X�^���X
   * @param obj               �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, Object  obj)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, obj);
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iint�^�j
   * @param context           OAPageContext�C���X�^���X
   * @param i                 �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OAPageContext context, int  i)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, String.valueOf(i));
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iObject�^�j
   * @param txn               OADBTransaction�C���X�^���X
   * @param i                 �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, int  i)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, String.valueOf(i));
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iObject�^�j
   * @param context           OAPageContext�C���X�^���X
   * @param b                 �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OAPageContext context, boolean  b)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, String.valueOf(b));
    }
  }

  /*****************************************************************************
   * �f�o�b�O���iObject�^�j
   * @param txn               OADBTransaction�C���X�^���X
   * @param b                 �f�o�b�O��
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, boolean  b)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, String.valueOf(b));
    }
  }

  /*****************************************************************************
   * URL�p�����[�^�擾
   * @param pageContext       OAPageContext�C���X�^���X
   * @param name              �p�����[�^��
   *****************************************************************************
   */
  public static String getUrlParameter(OAPageContext pageContext, String name)
  {
    String searchStatement = "&" + name + "=";
    String url = pageContext.getCurrentUrl();
    int index = url.indexOf(searchStatement);
    if ( index < 0 )
    {
      return null;
    }
    String valueStatement = url.substring(index + searchStatement.length());
    int nextIndex = valueStatement.indexOf("&");
    if ( nextIndex < 0 )
    {
      return valueStatement;
    }
    String value = valueStatement.substring(0, nextIndex);
    return value;
  }
  
  /*****************************************************************************
   * �f�o�b�O�o��
   * @param logger            OADBTransaction/OAPageContext
   * @param obj               �f�o�b�O��
   *****************************************************************************
   */
  private static void print(Object logger, Object obj)
  {
    Throwable t = new Throwable();
    StackTraceElement[] e = t.getStackTrace();

    StringBuffer sb = new StringBuffer();
    sb.append(e[2].getClassName());
    sb.append(".");
    sb.append(e[2].getMethodName());
    sb.append("()");
    sb.append(" [");
    sb.append(e[2].getLineNumber());
    sb.append("]");

    String msg = null;
    
    if ( obj != null )
    {
      msg = obj.toString();
    }
    else
    {
      msg = "null";
    }

    if ( logger instanceof OADBTransaction )
    {
      ((OADBTransaction)logger).writeDiagnostics(
          sb.toString()
         ,msg
         ,DEBUG_LEVEL
      );
    }

    if ( logger instanceof OAPageContext )
    {
      ((OAPageContext)logger).writeDiagnostics(
          sb.toString()
         ,msg
         ,DEBUG_LEVEL
      );
    }
  }
}