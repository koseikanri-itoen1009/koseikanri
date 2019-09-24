/*============================================================================
* ファイル名 : XxcmnUtility
* 概要説明   : 全体共通関数
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-10 1.0  二瓶大輔     新規作成
* 2008-08-13 1.1  二瓶大輔     chkNumericメソッド不具合修正
* 2008-12-10 1.2  伊藤ひとみ   本番障害#587対応
* 2019-09-05 1.3  小路恭弘     E_本稼動_15601対応
*============================================================================
*/
package itoen.oracle.apps.xxcmn.util;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
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
// 2019-09-05 Y.Shoji ADD START
import java.text.ParseException;
import java.text.SimpleDateFormat;
// 2019-09-05 Y.Shoji ADD END
/***************************************************************************
 * 全体共通関数クラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.2
 ***************************************************************************
 */
public class XxcmnUtility 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcmnUtility()
  {
  }
  /***************************************************************************
   * オブジェクトがブランクかどうかをチェックします。
   * @param obj - 値
   * @return String - true:ブランク、false:ブランク以外
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
   * オブジェクトを比較します。
   * @param obj1 - 比較対象１
   * @param obj2 - 比較対象２
   * @return boolean - true:等しい、false:等しくない
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
   * Number型の値をString型にキャストします。
   * @param value - Number型の値
   * @return String - String型の値
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
   * BigDecimal型の値をString型にキャストします。
   * @param value - BigDecimal型の値
   * @return String - String型の値
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
   * Date型の値をString型にキャストします。
   * @param value - Date型の値
   * @return String - String型の値
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
   * Number型の値をint型にキャストします。
   * @param value - Number型の値
   * @return String - int型の値
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
   * Number型の値をBigDecimal型にキャストします。
   * @param value - Number型の値
   * @return String - int型の値
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
   * Number型の値をdouble型にキャストします。
   * @param value - Number型の値
   * @return double - double型の値
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
   * Number型の値をlong型にキャストします。
   * @param value - Number型の値
   * @return long - long型の値
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
   * oracle.jbo.domain.Date型の値をjava.sql.Date型にキャストします。
   * @param value - oracle.jbo.domain.Date型の値
   * @return String - java.sql.Date型の値
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
   * 日付の比較します。
   * @param type - タイプ 1：> 2：≧
   * @param value1 - 値
   * @param value2 - 値
   * @return boolean - true:正しい、false:エラー
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
   * 数値の比較をします。
   * @param type - タイプ 1：> 2：≧ 3：=
   * @param obj1 - 値1
   * @param obj2 - 値2
   * @return boolean - true:正しい、false:エラー
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
   * 数値のチェックを行います。
   * @param value - 値
   * @param leftLength - 整数の桁数
   * @param rightLength - 小数点以下の桁数
   * @return boolean - true:正しい、false:エラー
   ***************************************************************************
   */
  public static boolean chkNumeric(Object value, int leftLength, int rightLength)
  {
    // ブランクの場合は正常終了
    if (isBlankOrNull(value)) 
    {
      return true;
    }
    // 「.」で始まっているまたは、「.」で終わっている場合はエラー
    if (value.toString().endsWith(".") || value.toString().startsWith(".")) 
    {
      return false;
    }
    // マイナスがある場合、位置が先頭以外の場合はエラー
    int mainus = value.toString().lastIndexOf("-");
    if (mainus > 0) 
    {
      return false;
    }
    // 「.」で分割
    String[] strSplit = value.toString().split("\\.", -1);
    // 小数部が0の場合は分割後の長さが1以外の場合エラー
    if (rightLength == 0 && strSplit.length != 1) 
    {
      return false;
    }
    // 分割後の配列が3個以上ある場合はエラー
// 2008/08/13 D.Nihei Mod Start
//    if (strSplit.length > 3) 
    if (strSplit.length >= 3) 
// 2008/08/13 D.Nihei Mod End
    {
      return false;  
    }
    // lengthのチェック
    for (int i=0 ;i<strSplit.length ; i++) 
    {
      String str = strSplit[i];
      switch (i) 
      {
        // 整数部
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
        // 小数部
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
   * ログを出力します。
   * @param   trans - OADBTransaction
   * @param   className - クラス名
   * @param   messageText - メッセージ 
   * @param   logLevel - ログレベル
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
   * ダイアログを生成します。
   * @param messageType - メッセージタイプ
   * @param pageContext - HttpServletResponse取得の為のOAFクラス
   * @param mainMessage - メインメッセージ
   * @param instMessage - インストラクションメッセージ
   * @param okButtonUrl - OKボタンURL
   * @param noButtonUrl - NOボタンURL
   * @param okButtonLabel - OKボタンラベル
   * @param noButtonLabel - NOボタンラベル
   * @param okButtonItemName - OKボタンアイテム名
   * @param noButtonItemName - NOボタンアイテム名
   * @param formParams - 送信パラメータ群
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
    // ダイアログ・オブジェクト作成
    OADialogPage dialogPage = new OADialogPage(
                                    messageType, 
                                    mainMessage, 
                                    instMessage, 
                                    okButtonUrl, 
                                    noButtonUrl);
    
    // OKボタン設定
    dialogPage.setOkButtonLabel(okButtonLabel);
    dialogPage.setOkButtonItemName(okButtonItemName);
    dialogPage.setOkButtonToPost(true);

    // NOボタン設定
    if(noButtonUrl != null)
    {
      dialogPage.setNoButtonLabel(noButtonLabel);
      dialogPage.setNoButtonItemName(noButtonItemName);
      dialogPage.setNoButtonToPost(true);
    }
    // retainAM設定
    dialogPage.setRetainAMValue(true);
    dialogPage.setPostToCallingPage(true);

    // パラメータ設定
    dialogPage.setFormParameters(formParams);

    // ダイアログ・ページにリダイレクト
    pageContext.redirectToDialogPage(dialogPage);
  } // createDialog

  /***************************************************************************
   * 動的に生成するSQLのWhere句にAND文字列を挿入します。
   * @param   whereClause - Where句
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
   * 文字列からカンマを除去します。
   * @param  src 編集対象文字列
   * @return String 編集済文字列
   ***************************************************************************
   */
  public static String commaRemoval(String src)
  {
    if (XxcmnUtility.isBlankOrNull(src)) 
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
   * 日付を計算して返します。。
   * @param  date - 対象日付
   * @param  i    - 増減日数
   * @return Date - 計算後日付
   ***************************************************************************
   */
  public static Date getDate(Date date , int i)
  {
    Date newDate = new Date(new java.sql.Date(date.dateValue().getTime() + i * (24*60*60*1000)));
    return newDate;
  }

  /*****************************************************************************
   * 採番関数からNoを取得します。
   * @param trans - トランザクション
   * @param tokenName - トークン名称
   * @return String - No
   * @throws OAException OA例外
   ****************************************************************************/
  public static String getSeqNo(
    OADBTransaction trans,
    String tokenName
    ) throws OAException
  {
    String apiName   = "getSeqNo";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  xxcmn_common_pkg.get_seq_no( ");
    sb.append("    iv_seq_class =>  '1'  "); // 採番区分
    sb.append("   ,ov_seq_no    =>  :1   "); // 採番した固定長12桁の番号
    sb.append("   ,ov_errbuf    =>  :2   "); // エラー・メッセージ
    sb.append("   ,ov_retcode   =>  :3   "); // リターン・コード
    sb.append("   ,ov_errmsg    =>  :4   "); // ユーザー・エラー・メッセージ
    sb.append("    ); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      int i = 1;
      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      cstmt.registerOutParameter(i++, Types.VARCHAR);

      // PL/SQL実行
      cstmt.execute();

      if (XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        return cstmt.getString(1);
      } else
      {
        // ロールバック
        rollBack(trans);
        // APIエラーを出力する。
        XxcmnUtility.writeLog(trans,
                              XxcmnConstants.CLASS_XXCMN_UTILITY + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                   tokenName + "の取得") };
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN05002, 
                              tokens);
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // ログに出力
      XxcmnUtility.writeLog(trans,
                            XxcmnConstants.CLASS_XXCMN_UTILITY + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        XxcmnUtility.writeLog(trans,
                              XxcmnConstants.CLASS_XXCMN_UTILITY + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getSeqNo

  /***************************************************************************
   * ロールバック処理を行うメソッドです。
   * @param trans - トランザクション
   ***************************************************************************
   */
  public static void rollBack(
    OADBTransaction trans
  )
  {
    // ロールバック発行
    trans.executeCommand("ROLLBACK ");
  } // rollBack

  /*****************************************************************************
   * プロファイルオプション値を取得します。
   * @param trans       - トランザクション
   * @param profileName - プロファイル名
   * @return String - プロファイルオプション値
   ****************************************************************************/
  public static String getProfileValue(
    OADBTransaction trans,
    String profileName
    )
  {

    return trans.getProfile(profileName);

  } // getProfileValue
  
  /*****************************************************************************
   * 日付の書式チェックを行います。
   * @param trans   - トランザクション
   * @param strDate - 日付文字列
   * @param format  - 書式("YYYY/MM/DD"など)
   * @return boolean - true:正しい、false:エラー
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean chkDateFormat(
    OADBTransaction trans,
     String strDate,
     String format
  ) throws OAException
  {
    String apiName   = "chkDateFormat";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(100);
    sb.append("DECLARE "                       );
    sb.append("  ld_temp DATE; "               );
    sb.append("BEGIN "                         );
    sb.append("  ld_temp := TO_DATE(:1,:2); "  );
    sb.append("END; "                          );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(1, strDate); // 日付文字列
      cstmt.setString(2, format);  // 書式

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      rollBack(trans);
      // エラーを返す
      return false;

    } finally
    {
      try
      {
        cstmt.close();

      // クローズ中にエラーが発生した場合
      } catch(SQLException s)
      {
        // ロールバック
        rollBack(trans);
        // ログ出力
        writeLog(trans,
                 XxcmnConstants.CLASS_XXCMN_UTILITY + XxcmnConstants.DOT + apiName,
                 s.toString(),
                 6);
        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
    return true;
  } // chkDateFormat

  /***************************************************************************
   * 処理成功メッセージ表示を行うメソッドです。
   * @param tokenName - トークン値
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public static void putSuccessMessage(
    String tokenName
    ) throws OAException
  {
    //トークンを生成します。
    MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                               tokenName) };
    // 処理成功メッセージ
    throw new OAException(
      XxcmnConstants.APPL_XXCMN,
      XxcmnConstants.XXCMN05001, 
      tokens,
      OAException.INFORMATION, 
      null);

  } // putSuccessMessage

  /***************************************************************************
   * 処理失敗メッセージ表示を行うメソッドです。
   * @param tokenName - トークン値
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public static void putErrorMessage(
    String tokenName
    ) throws OAException
  {
    //トークンを生成します。
    MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                               tokenName) };
    // 処理成功メッセージ
    throw new OAException(
      XxcmnConstants.APPL_XXCMN,
      XxcmnConstants.XXCMN05002, 
      tokens,
      OAException.ERROR, 
      null);

  } // putErrorMessage

  /***************************************************************************
   * 文字列(StringBuffer)に改行を追加するメソッドです。
   * @param sb - 文字列
   ***************************************************************************
   */
  public static void newLineAppend(StringBuffer sb)
  {
    // 文字列がある場合は改行コードを追加
    if (sb.length() > 0)
    {
      sb.append(XxcmnConstants.CHANGING_LINE_CODE);
      sb.append(XxcmnConstants.CHANGING_LINE_CODE);
    }
  } // newLineAppend      

  /*****************************************************************************
   * シーケンスを取得します。
   * @param trans   - トランザクション
   * @param seqName  - シーケンス名
   * @return Number - シーケンス
   ****************************************************************************/
  public static Number getSeq(
    OADBTransaction trans,
    String seqName
    )
  {
    if (XxcmnUtility.isBlankOrNull(seqName)) 
    {
      return null;
    }    
    return trans.getSequenceValue(seqName);

  }
  /***************************************************************************
   * 数値を指定した表示書式にします。
   * @param  targetNumber    - 対象の数値
   * @param  maxPlace        - 最大整数部桁数
   * @param  minDecimal      - 最小小数点桁数
   * @param  pause           - カンマ区切り(TRUE=区切る、FALSE=区切らない)
   * @return String          - 指定の書式の文字列に変換された数値
   * @throws OAException     - OA例外
   ***************************************************************************
   */
  public static String formConvNumber(
    Double targetNumber,
    int maxPlace,
    int minDecimal,
    boolean pause 
  ) throws OAException
  {
    String formConvNumber = null; //RETURN値格納用文字列
    // 対象の数値が入力されていない場合は処理を行わない
    if (XxcmnUtility.isBlankOrNull(targetNumber))
    {
      return null;
    }
    // NumberFormatを宣言
    NumberFormat nf = NumberFormat.getInstance();
    // 整数部の最大桁数を指定
    nf.setMaximumIntegerDigits(maxPlace);
    // 小数部の最小桁数を指定
    nf.setMinimumFractionDigits(minDecimal);
    // カンマ区切りの有無を指定
    nf.setGroupingUsed(pause);
    // 指定の数値を文字列に変換
    formConvNumber = nf.format(targetNumber.doubleValue());
    return formConvNumber;
  }
// 2008-12-10 H.Itou Add Start
  /***************************************************************************
   * String型の値をBigDecimal型にキャストします。
   * @param value - String型の値
   * @return String - BigDecimal型の値
   ***************************************************************************
   */
  public static BigDecimal bigDecimalValue(String value)
  {
    if (isBlankOrNull(value))
    {
      return new BigDecimal(0);
    }
    return new BigDecimal(value);
  } // bigDecimalValue
// 2008-12-10 H.Itou Add End
// 2019-09-05 Y.Shoji ADD START
  /***************************************************************************
   * String型の値(yyyy/MM)java.sql.Date型にキャストします。
   * @param value - String型の値
   * @return sqldate - java.sql.Date型の値
   ***************************************************************************
   */
  public static java.sql.Date dateValue(String value)
  {
    if (isBlankOrNull(value))
    {
      return null;
    } else {
      try{
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy/MM");
        java.util.Date utilDate = sdf.parse(value);
        java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
        return sqlDate;
      } catch (ParseException e) {
          e.printStackTrace();
        }
      return null;
    }
  } // dateValue
  /***************************************************************************
   * String型の値(yyyy/MM)をoracle.jbo.domain.Date型にキャストします。
   * @param value - String型の値
   * @return date - oracle.jbo.domain.Date型の値
   ***************************************************************************
   */
  public static Date dateValueOra(String value)
  {
    if (isBlankOrNull(value))
    {
      return null;
    } else {
      try{
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy/MM");
        java.util.Date utilDate = sdf.parse(value);
        java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
        Date date = new Date(sqlDate);
        return date;
      } catch (ParseException e) {
          e.printStackTrace();
        }
      return null;
    }
  } // dateValueOra
// 2019-09-05 Y.Shoji ADD END
}