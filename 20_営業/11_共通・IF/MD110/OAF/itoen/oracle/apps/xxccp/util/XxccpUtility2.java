/*============================================================================
* �t�@�C���� : XxccpUtility2
* �T�v����   : �S�̋��ʊ֐�
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.util;
import itoen.oracle.apps.xxccp.util.XxccpConstants;
import java.math.BigDecimal;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.text.NumberFormat;

import java.util.Hashtable;
import java.util.StringTokenizer;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �S�̋��ʊ֐��N���X�ł��B
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpUtility2 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpUtility2()
  {
  }
  /***************************************************************************
   * �I�u�W�F�N�g���u�����N���ǂ������`�F�b�N���܂��B
   * @param obj - �l
   * @return String - true:�u�����N�Afalse:�u�����N�ȊO
   ***************************************************************************
   */
  public static boolean isBlankOrNull(Object obj)
  {
    if (obj == null)
    {
      return true;
    }
    if ("".equals(obj))
    {
      return true;
    }
    return false;
  } // isBlankOrNull

  /*****************************************************************************
   * �I�u�W�F�N�g���r���܂��B
   * @param obj1 - ��r�ΏۂP
   * @param obj2 - ��r�ΏۂQ
   * @return boolean - true:�������Afalse:�������Ȃ�
   ****************************************************************************/
  public static boolean isEquals(Object obj1, Object obj2)
  {
    if (obj1 == obj2) 
    {
      return true;  
    }
    if ((obj1 == null)  || (obj2 == null)) 
    {
      return false;
    }
    return obj1.equals(obj2);
  } // isEquals

  /***************************************************************************
   * Number�^�̒l��String�^�ɃL���X�g���܂��B
   * @param value - Number�^�̒l
   * @return String - String�^�̒l
   ***************************************************************************
   */
  public static String stringValue(Number value)
  {
    if (isBlankOrNull(value))
    {
      return null;
    }
    return value.stringValue();
  } // stringValue

  /***************************************************************************
   * BigDecimal�^�̒l��String�^�ɃL���X�g���܂��B
   * @param value - BigDecimal�^�̒l
   * @return String - String�^�̒l
   ***************************************************************************
   */
  public static String stringValue(BigDecimal value)
  {
    if (isBlankOrNull(value))
    {
      return null;
    }
    return value.toString();
  } // stringValue
  
  /***************************************************************************
   * Date�^�̒l��String�^�ɃL���X�g���܂��B
   * @param value - Date�^�̒l
   * @return String - String�^�̒l
   ***************************************************************************
   */
  public static String stringValue(Date value)
  {
    String stringValue = null;
    
    if (isBlankOrNull(value))
    {
      return null;
    }
    
    try
    {
      stringValue = value.toText("YYYY/MM/DD",null);      
      
    } catch(SQLException s)
    {
      return null;
    }
    return stringValue;
  } // stringValue

  /***************************************************************************
   * Number�^�̒l��int�^�ɃL���X�g���܂��B
   * @param value - Number�^�̒l
   * @return String - int�^�̒l
   ***************************************************************************
   */
  public static int intValue(Number value)
  {
    if (isBlankOrNull(value))
    {
      return Types.NULL;
    }
    return value.intValue();
  } // intValue

  /***************************************************************************
   * Number�^�̒l��BigDecimal�^�ɃL���X�g���܂��B
   * @param value - Number�^�̒l
   * @return String - int�^�̒l
   ***************************************************************************
   */
  public static BigDecimal bigDecimalValue(Number value)
  {
    if (isBlankOrNull(value))
    {
      return new BigDecimal(0);
    }
    return value.bigDecimalValue();
  } // bigDecimalValue

  /***************************************************************************
   * Number�^�̒l��double�^�ɃL���X�g���܂��B
   * @param value - Number�^�̒l
   * @return double - double�^�̒l
   ***************************************************************************
   */
  public static double doubleValue(Number value)
  {
    if (isBlankOrNull(value))
    {
      return Types.NULL;
    }
    return value.doubleValue();
  } // doubleValue

  /***************************************************************************
   * Number�^�̒l��long�^�ɃL���X�g���܂��B
   * @param value - Number�^�̒l
   * @return long - long�^�̒l
   ***************************************************************************
   */
  public static long longValue(Number value)
  {
    if (isBlankOrNull(value))
    {
      return Types.NULL;
    }
    return value.longValue();
  } // longValue

  /***************************************************************************
   * oracle.jbo.domain.Date�^�̒l��java.sql.Date�^�ɃL���X�g���܂��B
   * @param value - oracle.jbo.domain.Date�^�̒l
   * @return String - java.sql.Date�^�̒l
   ***************************************************************************
   */
  public static java.sql.Date dateValue(Date value)
  {
    if (isBlankOrNull(value))
    {
      return null;
    }
    return value.dateValue();
  } // dateValue

  /***************************************************************************
   * ���t�̔�r���܂��B
   * @param type - �^�C�v 1�F> 2�F��
   * @param value1 - �l
   * @param value2 - �l
   * @return boolean - true:�������Afalse:�G���[
   ***************************************************************************
   */
  public static boolean chkCompareDate(int type, Date value1, Date value2)
  {
    if (type == 1) 
    {
      if (value1.timestampValue().getTime() > value2.timestampValue().getTime()) 
      {
        return true;
      } else 
      {
        return false;
      }
    } else if (type == 2)
    {
      if (value1.timestampValue().getTime() >= value2.timestampValue().getTime()) 
      {
        return true;
      } else 
      {
        return false;
      }
    }
    return false;

  } // chkCompareDate

  /***************************************************************************
   * ���l�̔�r�����܂��B
   * @param type - �^�C�v 1�F> 2�F�� 3�F=
   * @param obj1 - �l1
   * @param obj2 - �l2
   * @return boolean - true:�������Afalse:�G���[
   ***************************************************************************
   */
  public static boolean chkCompareNumeric(int type, Object obj1, Object obj2)
  {
    try 
    {
      if (isBlankOrNull(obj1)) 
      {
        obj1 = new Number(0);
      }
      if (isBlankOrNull(obj2)) 
      {
        obj2 = new Number(0);
      }
      Number num1 = obj1.getClass() == Number.class ? (Number)obj1 : new Number(obj1);
      Number num2 = obj2.getClass() == Number.class ? (Number)obj2 : new Number(obj2);

      int i = num1.compareTo(num2);
      if (type == 1) 
      {
        if (i > 0) 
        {
          return true;
        } else 
        {
          return false;
        }
      } else if (type == 2)
      {
        if (i >= 0) 
        {
          return true;
        } else 
        {
          return false;
        }
      } else if (type == 3)
      {
        if (i == 0) 
        {
          return true;
        } else 
        {
          return false;
        }
      }
      return false;
    } catch (SQLException ex) 
    {
      return false;
    }
  } // chkCompareNumeric

  /***************************************************************************
   * ���l�̃`�F�b�N���s���܂��B
   * @param value - �l
   * @param leftLength - �����̌���
   * @param rightLength - �����_�ȉ��̌���
   * @return boolean - true:�������Afalse:�G���[
   ***************************************************************************
   */
  public static boolean chkNumeric(Object value, int leftLength, int rightLength)
  {
    // �u�����N�̏ꍇ�͐���I��
    if (isBlankOrNull(value)) 
    {
      return true;
    }
    // �u.�v�Ŏn�܂��Ă���܂��́A�u.�v�ŏI����Ă���ꍇ�̓G���[
    if (value.toString().endsWith(".") || value.toString().startsWith(".")) 
    {
      return false;
    }
    // �}�C�i�X������ꍇ�A�ʒu���擪�ȊO�̏ꍇ�̓G���[
    int mainus = value.toString().lastIndexOf("-");
    if (mainus > 0) 
    {
      return false;
    }
    // �u.�v�ŕ���
    String[] strSplit = value.toString().split("\\.", -1);
    // ��������0�̏ꍇ�͕�����̒�����1�ȊO�̏ꍇ�G���[
    if (rightLength == 0 && strSplit.length != 1) 
    {
      return false;
    }
    // ������̔z��3�ȏ゠��ꍇ�̓G���[
// 2008/08/13 D.Nihei Mod Start
//    if (strSplit.length > 3) 
    if (strSplit.length >= 3) 
// 2008/08/13 D.Nihei Mod End
    {
      return false;  
    }
    // length�̃`�F�b�N
    for (int i=0 ;i<strSplit.length ; i++) 
    {
      String str = strSplit[i];
      switch (i) 
      {
        // ������
        case 0:
          {
            String str2 = str.replaceAll("-","");
            if (str2.length() > leftLength) 
            {
              return false;  
            }
            for (int y = 0; y < str2.length(); y++)
            {
              char c  =  str2.charAt(y);
              if (c < '0' || c > '9')
              {
                return false;
              }
            }
          }
          break;
        // ������
        case 1:
          {
            if (str.length() > rightLength) 
            {
              return false;  
            }
            for (int y = 0; y < str.length(); y++)
            {
              char c  =  str.charAt(y);
              if (c < '0' || c > '9')
              {
                return false;
              }
            }
          }
          break;
      }
    }
    return true;
  } // chkNumeric

  /***************************************************************************
   * ���O���o�͂��܂��B
   * @param   trans - OADBTransaction
   * @param   className - �N���X��
   * @param   messageText - ���b�Z�[�W 
   * @param   logLevel - ���O���x��
   ***************************************************************************
   */
  public static void writeLog(
    OADBTransaction trans,
    String className,
    String messageText,
    int logLevel)
  {
    if (trans.isLoggingEnabled(logLevel))
    {
      trans.writeDiagnostics(className, messageText, logLevel);
    }
  } // writeLog

  /***************************************************************************
   * �_�C�A���O�𐶐����܂��B
   * @param messageType - ���b�Z�[�W�^�C�v
   * @param pageContext - HttpServletResponse�擾�ׂ̈�OAF�N���X
   * @param mainMessage - ���C�����b�Z�[�W
   * @param instMessage - �C���X�g���N�V�������b�Z�[�W
   * @param okButtonUrl - OK�{�^��URL
   * @param noButtonUrl - NO�{�^��URL
   * @param okButtonLabel - OK�{�^�����x��
   * @param noButtonLabel - NO�{�^�����x��
   * @param okButtonItemName - OK�{�^���A�C�e����
   * @param noButtonItemName - NO�{�^���A�C�e����
   * @param formParams - ���M�p�����[�^�Q
   ***************************************************************************
   */
  public static void createDialog(byte messageType, 
                                    OAPageContext pageContext, 
                                    OAException mainMessage, 
                                    OAException instMessage, 
                                    String okButtonUrl, 
                                    String noButtonUrl, 
                                    String okButtonLabel, 
                                    String noButtonLabel, 
                                    String okButtonItemName, 
                                    String noButtonItemName, 
                                    Hashtable formParams )
  {
    // �_�C�A���O�E�I�u�W�F�N�g�쐬
    OADialogPage dialogPage = new OADialogPage(
                                    messageType, 
                                    mainMessage, 
                                    instMessage, 
                                    okButtonUrl, 
                                    noButtonUrl);
    
    // OK�{�^���ݒ�
    dialogPage.setOkButtonLabel(okButtonLabel);
    dialogPage.setOkButtonItemName(okButtonItemName);
    dialogPage.setOkButtonToPost(true);

    // NO�{�^���ݒ�
    if(noButtonUrl != null)
    {
      dialogPage.setNoButtonLabel(noButtonLabel);
      dialogPage.setNoButtonItemName(noButtonItemName);
      dialogPage.setNoButtonToPost(true);
    }
    // retainAM�ݒ�
    dialogPage.setRetainAMValue(true);
    dialogPage.setPostToCallingPage(true);

    // �p�����[�^�ݒ�
    dialogPage.setFormParameters(formParams);

    // �_�C�A���O�E�y�[�W�Ƀ��_�C���N�g
    pageContext.redirectToDialogPage(dialogPage);
  } // createDialog

  /***************************************************************************
   * ���I�ɐ�������SQL��Where���AND�������}�����܂��B
   * @param   whereClause - Where��
   ***************************************************************************
   */
  public static void andAppend(
    StringBuffer whereClause
    )
  {
    if (whereClause.length() != 0)
    {
      whereClause.append(" AND ");
    }
  } // andAppend

  /***************************************************************************
   * �����񂩂�J���}���������܂��B
   * @param  src �ҏW�Ώە�����
   * @return String �ҏW�ϕ�����
   ***************************************************************************
   */
  public static String commaRemoval(String src)
  {
    if (XxccpUtility2.isBlankOrNull(src)) 
    {
      return src;
    }
    StringTokenizer token = new StringTokenizer(src, ",");
    String retStr = "";
  
    StringBuffer strBuff = new StringBuffer();
  
    while (token.hasMoreTokens())
    {
        strBuff.append(token.nextToken());
    }
  
    retStr = strBuff.toString();
  
    return retStr;
  }
  /***************************************************************************
   * ���t���v�Z���ĕԂ��܂��B�B
   * @param  date - �Ώۓ��t
   * @param  i    - ��������
   * @return Date - �v�Z����t
   ***************************************************************************
   */
  public static Date getDate(Date date , int i)
  {
    Date newDate = new Date(new java.sql.Date(date.dateValue().getTime() + i * (24*60*60*1000)));
    return newDate;
  }

  /*****************************************************************************
   * �̔Ԋ֐�����No���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @param tokenName - �g�[�N������
   * @return String - No
   * @throws OAException OA��O
   ****************************************************************************/
  public static String getSeqNo(
    OADBTransaction trans,
    String tokenName
    ) throws OAException
  {
    String apiName   = "getSeqNo";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("    XXCCP_MRP_FILE_UL_S1.get_seq_no( ");
    sb.append("    iv_seq_class =>  '1'  "); // �̔ԋ敪
    sb.append("   ,ov_seq_no    =>  :1   "); // �̔Ԃ����Œ蒷12���̔ԍ�
    sb.append("   ,ov_errbuf    =>  :2   "); // �G���[�E���b�Z�[�W
    sb.append("   ,ov_retcode   =>  :3   "); // ���^�[���E�R�[�h
    sb.append("   ,ov_errmsg    =>  :4   "); // ���[�U�[�E�G���[�E���b�Z�[�W
    sb.append("    ); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(OUT�p�����[�^)
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL���s
      cstmt.execute();

      if (XxccpConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        return cstmt.getString(1);
      } else
      {
        // ���[���o�b�N
        rollBack(trans);
        // API�G���[���o�͂���B
        XxccpUtility2.writeLog(trans,
                              XxccpConstants.CLASS_XXCCP_UTILITY2 + XxccpConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxccpConstants.TOKEN_PROCESS,
                                                   tokenName + "�̎擾") };
        throw new OAException(XxccpConstants.APPL_XXCCP, 
                              XxccpConstants.XXCCP191005, 
                              tokens);
      }

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // ���O�ɏo��
      XxccpUtility2.writeLog(trans,
                            XxccpConstants.CLASS_XXCCP_UTILITY2 + XxccpConstants.DOT + apiName,
                            s.toString(),
                            6);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxccpConstants.APPL_XXCCP, 
                            XxccpConstants.XXCCP191003);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        XxccpUtility2.writeLog(trans,
                              XxccpConstants.CLASS_XXCCP_UTILITY2 + XxccpConstants.DOT + apiName,
                              s.toString(),
                              6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxccpConstants.APPL_XXCCP, 
                              XxccpConstants.XXCCP191003);
      }
    }
  } // getSeqNo

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   ***************************************************************************
   */
  public static void rollBack(
    OADBTransaction trans
  )
  {
    // ���[���o�b�N���s
    trans.executeCommand("ROLLBACK ");
  } // rollBack

  /*****************************************************************************
   * �v���t�@�C���I�v�V�����l���擾���܂��B
   * @param trans       - �g�����U�N�V����
   * @param profileName - �v���t�@�C����
   * @return String - �v���t�@�C���I�v�V�����l
   ****************************************************************************/
  public static String getProfileValue(
    OADBTransaction trans,
    String profileName
    )
  {

    return trans.getProfile(profileName);

  } // getProfileValue
  
  /*****************************************************************************
   * ���t�̏����`�F�b�N���s���܂��B
   * @param trans   - �g�����U�N�V����
   * @param strDate - ���t������
   * @param format  - ����("YYYY/MM/DD"�Ȃ�)
   * @return boolean - true:�������Afalse:�G���[
   * @throws OAException - OA��O
   ****************************************************************************/
  public static boolean chkDateFormat(
    OADBTransaction trans,
     String strDate,
     String format
  ) throws OAException
  {
    String apiName   = "chkDateFormat";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE "                       );
    sb.append("  ld_temp DATE; "               );
    sb.append("BEGIN "                         );
    sb.append("  ld_temp := TO_DATE(:1,:2); "  );
    sb.append("END; "                          );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(1, strDate); // ���t������
      cstmt.setString(2, format);  // ����

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      rollBack(trans);
      // �G���[��Ԃ�
      return false;

    } finally
    {
      try
      {
        cstmt.close();

      // �N���[�Y���ɃG���[�����������ꍇ
      } catch(SQLException s)
      {
        // ���[���o�b�N
        rollBack(trans);
        // ���O�o��
        writeLog(trans,
                 XxccpConstants.CLASS_XXCCP_UTILITY2 + XxccpConstants.DOT + apiName,
                 s.toString(),
                 6);
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxccpConstants.APPL_XXCCP, 
                              XxccpConstants.XXCCP191003);
      }
    }
    return true;
  } // chkDateFormat

  /***************************************************************************
   * �����������b�Z�[�W�\�����s�����\�b�h�ł��B
   * @param tokenName - �g�[�N���l
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static void putSuccessMessage(
    String tokenName
    ) throws OAException
  {
    //�g�[�N���𐶐����܂��B
    MessageToken[] tokens = { new MessageToken(XxccpConstants.TOKEN_PROCESS,
                                               tokenName) };
    // �����������b�Z�[�W
    throw new OAException(
      XxccpConstants.APPL_XXCCP,
      XxccpConstants.XXCCP191004, 
      tokens,
      OAException.INFORMATION, 
      null);

  } // putSuccessMessage

  /***************************************************************************
   * �������s���b�Z�[�W�\�����s�����\�b�h�ł��B
   * @param tokenName - �g�[�N���l
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public static void putErrorMessage(
    String tokenName
    ) throws OAException
  {
    //�g�[�N���𐶐����܂��B
    MessageToken[] tokens = { new MessageToken(XxccpConstants.TOKEN_PROCESS,
                                               tokenName) };
    // �������s���b�Z�[�W
    throw new OAException(
      XxccpConstants.APPL_XXCCP,
      XxccpConstants.XXCCP191005, 
      tokens,
      OAException.ERROR, 
      null);

  } // putErrorMessage

  /***************************************************************************
   * ������(StringBuffer)�ɉ��s��ǉ����郁�\�b�h�ł��B
   * @param sb - ������
   ***************************************************************************
   */
  public static void newLineAppend(StringBuffer sb)
  {
    // �����񂪂���ꍇ�͉��s�R�[�h��ǉ�
    if (sb.length() > 0)
    {
      sb.append(XxccpConstants.CHANGING_LINE_CODE);
      sb.append(XxccpConstants.CHANGING_LINE_CODE);
    }
  } // newLineAppend      

  /*****************************************************************************
   * �V�[�P���X���擾���܂��B
   * @param trans   - �g�����U�N�V����
   * @param seqName  - �V�[�P���X��
   * @return Number - �V�[�P���X
   ****************************************************************************/
  public static Number getSeq(
    OADBTransaction trans,
    String seqName
    )
  {
    if (XxccpUtility2.isBlankOrNull(seqName)) 
    {
      return null;
    }    
    return trans.getSequenceValue(seqName);

  }
  /***************************************************************************
   * ���l���w�肵���\�������ɂ��܂��B
   * @param  targetNumber    - �Ώۂ̐��l
   * @param  maxPlace        - �ő吮��������
   * @param  minDecimal      - �ŏ������_����
   * @param  pause           - �J���}��؂�(TRUE=��؂�AFALSE=��؂�Ȃ�)
   * @return String          - �w��̏����̕�����ɕϊ����ꂽ���l
   * @throws OAException     - OA��O
   ***************************************************************************
   */
  public static String formConvNumber(
    Double targetNumber,
    int maxPlace,
    int minDecimal,
    boolean pause 
  ) throws OAException
  {
    String formConvNumber = null; //RETURN�l�i�[�p������
    // �Ώۂ̐��l�����͂���Ă��Ȃ��ꍇ�͏������s��Ȃ�
    if (XxccpUtility2.isBlankOrNull(targetNumber))
    {
      return null;
    }
    // NumberFormat��錾
    NumberFormat nf = NumberFormat.getInstance();
    // �������̍ő包�����w��
    nf.setMaximumIntegerDigits(maxPlace);
    // �������̍ŏ��������w��
    nf.setMinimumFractionDigits(minDecimal);
    // �J���}��؂�̗L�����w��
    nf.setGroupingUsed(pause);
    // �w��̐��l�𕶎���ɕϊ�
    formConvNumber = nf.format(targetNumber.doubleValue());
    return formConvNumber;
  }

}